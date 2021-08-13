import Combine
import MetalKit
import SwiftUI


/// View for displaying new pixel buffers that are emitted by the given `pixelBufferPublisher`.
final class PreviewMetalView: MTKView {

    /// The image that should be displayed next.
    private var imageToDisplay: CIImage?

    private lazy var commandQueue = self.device?.makeCommandQueue()
    private lazy var context: CIContext = {
        guard let device = self.device else {
            assertionFailure("The PreviewUIView should have a Metal device")
            return CIContext()
        }
        return CIContext(mtlDevice: device)
    }()


    init(device: MTLDevice?, imagePublisher: AnyPublisher<CIImage?, Never>) {
        super.init(frame: .zero, device: device)

        // setup view to only draw when we need it (i.e., a new pixel buffer arrived),
        // not continuously
        self.isPaused = true
        self.enableSetNeedsDisplay = true
        self.autoResizeDrawable = true

        #if os(iOS)
        // we only need a wider gamut pixel format if the display supports it
        self.colorPixelFormat = (self.traitCollection.displayGamut == .P3) ? .bgr10_xr_srgb : .bgra8Unorm_srgb
        #endif
        // this is important, otherwise Core Image could not render into the
        // view's framebuffer directly
        self.framebufferOnly = false
        self.clearColor = MTLClearColor(red: 0, green: 0, blue: 0, alpha: 0)

        // try to display an image as soon as it is published
        imagePublisher.bind(to: self) { me, image in
            me.imageToDisplay = image
            #if os(iOS)
            me.setNeedsDisplay()
            #elseif os(OSX)
            me.needsDisplay = true
            #endif
        }
    }

    @available(*, unavailable)
    required init(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }


    override func draw(_ rect: CGRect) {
        guard let input = self.imageToDisplay,
              let currentDrawable = self.currentDrawable,
              let commandBuffer = self.commandQueue?.makeCommandBuffer() else { return }

        // scale to fit into view
        let drawableSize = self.drawableSize
        let scaleX = drawableSize.width / input.extent.width
        let scaleY = drawableSize.height / input.extent.height
        let scale = min(scaleX, scaleY)
        let scaledImage = input.transformed(by: CGAffineTransform(scaleX: scale, y: scale))

        // center in the view
        let originX = max(drawableSize.width - scaledImage.extent.size.width, 0) / 2
        let originY = max(drawableSize.height - scaledImage.extent.size.height, 0) / 2
        let centeredImage = scaledImage.transformed(by: CGAffineTransform(translationX: originX, y: originY))

        // Create a render destination that allows to lazily fetch the target texture
        // which allows the encoder to process all CI commands _before_ the texture is actually available.
        // This gives a nice speed boost because the CPU doesn't need to wait for the GPU to finish
        // before starting to encode the next frame.
        // Also note that we don't pass a command buffer here, because according to Apple:
        // "Rendering to a CIRenderDestination initialized with a commandBuffer requires encoding all
        // the commands to render an image into the specified buffer. This may impact system responsiveness
        // and may result in higher memory usage if the image requires many passes to render."
        let destination = CIRenderDestination(width: Int(drawableSize.width),
                                              height: Int(drawableSize.height),
                                              pixelFormat: self.colorPixelFormat,
                                              commandBuffer: nil,
                                              mtlTextureProvider: { () -> MTLTexture in
                                                return currentDrawable.texture
        })

        do {
            try self.context.startTask(toClear: destination)
            try self.context.startTask(toRender: centeredImage, to: destination)
        } catch {
            assertionFailure("Failed to render to preview view: \(error)")
        }

        commandBuffer.present(currentDrawable)
        commandBuffer.commit()
    }

}

#if os(iOS)
/// Helper for making PreviewMetalView available in SwiftUI.
struct PreviewView: UIViewRepresentable {

    let imagePublisher: AnyPublisher<CIImage?, Never>


    func makeUIView(context: Context) -> PreviewMetalView {
        return PreviewMetalView(device: MTLCreateSystemDefaultDevice(), imagePublisher:  self.imagePublisher)
    }

    func updateUIView(_ uiView: PreviewMetalView, context: Context) {

    }

}
#endif

#if os(OSX)
/// Helper for making PreviewMetalView available in SwiftUI.
struct PreviewView: NSViewRepresentable {

    let imagePublisher: AnyPublisher<CIImage?, Never>


    func makeNSView(context: Context) -> PreviewMetalView {
        return PreviewMetalView(device: MTLCreateSystemDefaultDevice(), imagePublisher:  self.imagePublisher)
    }

    func updateNSView(_ nsView: PreviewMetalView, context: Context) {

    }

}
#endif


struct PreviewView_Previews: PreviewProvider {
    static var previews: some View {
        let previewImage = CIFilter(name: "CICheckerboardGenerator")?.outputImage?.cropped(to: CGRect(x: 0, y: 0, width: 1000, height: 1000))
        PreviewView(imagePublisher: Just(previewImage).eraseToAnyPublisher())
    }
}
