import CoreImage
import Combine


class FilteredImageProvider: ObservableObject {

    @Published var filteredImage: CIImage?

}


/// Very simple controller for transforming incoming `CVPixelBuffer`s into
/// filtered `CIImage`s – all via Combine publishers.
class FilterController {

    let filteredImageProvider = FilteredImageProvider()

    private let filter = CIFilter(name: "CIComicEffect")!


    init(pixelBufferPublisher: AnyPublisher<CVPixelBuffer?, Never>) {
        pixelBufferPublisher
            // transform the pixel buffer into an `CIImage`...
            .map { $0.flatMap({ CIImage(cvPixelBuffer: $0) }) }
            // ... apply the filter to it...
            .map { [weak filter = self.filter] inputImage -> CIImage? in
                filter?.setValue(inputImage, forKey: kCIInputImageKey)
                return filter?.outputImage
            }
            // ... and pass it to the output publisher
            .assign(to: &self.filteredImageProvider.$filteredImage)
    }

}
