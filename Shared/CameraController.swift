import AVFoundation
import Combine


class PreviewPixelBufferProvider: ObservableObject {

    @Published var previewPixelBuffer: CVPixelBuffer?

}


/// Controller of the `AVCaptureSession` that will manage the interface to the camera
/// and will publish new frames via the `previewPixelBufferProvider`.
class CameraController {

    let previewPixelBufferProvider = PreviewPixelBufferProvider()
    lazy private var previewPixelBufferDelegate = PreviewPixelBufferDelegate(previewPixelBufferProvider: self.previewPixelBufferProvider)

    private let captureSession = AVCaptureSession()
    private let sessionQueue = DispatchQueue(label: "Session Queue")

    private var videoDeviceInput: AVCaptureDeviceInput!
    private let videoDataOutput = AVCaptureVideoDataOutput()

    private lazy var videoOutputQueue = DispatchQueue(label: "Video Output Queue")

    #if os(iOS)
    private let orientationObserver = OrientationObserver()
    #endif

    private var subscriptions = Set<AnyCancellable>()


    init() {
        self.sessionQueue.async {
            self.configureSession()
        }
    }

    private func configureSession() {
        self.captureSession.beginConfiguration()
        defer { self.captureSession.commitConfiguration() }

        self.captureSession.sessionPreset = .photo

        // add video input
        do {
            var defaultVideoDevice: AVCaptureDevice?

            // default to a wide angle back camera
            if let backCameraDevice = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back) {
                defaultVideoDevice = backCameraDevice
            } else if let frontCameraDevice = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .front) {
                // if the rear wide angle camera isn't available, default to the front wide angle camera
                defaultVideoDevice = frontCameraDevice
            }
            guard let videoDevice = defaultVideoDevice else {
                assertionFailure("Default video device is unavailable.")
                return
            }
            let videoDeviceInput = try AVCaptureDeviceInput(device: videoDevice)

            if self.captureSession.canAddInput(videoDeviceInput) {
                self.captureSession.addInput(videoDeviceInput)
                self.videoDeviceInput = videoDeviceInput
            } else {
                assertionFailure("Couldn't add video device input to the session.")
                return
            }
        } catch {
            assertionFailure("Couldn't create video device input: \(error)")
            return
        }

        // add the video data output; this will vend us new frames from the camera
        if self.captureSession.canAddOutput(self.videoDataOutput) {
            self.captureSession.addOutput(self.videoDataOutput)

            self.videoDataOutput.setSampleBufferDelegate(self.previewPixelBufferDelegate, queue: self.videoOutputQueue)

            #if os(iOS)
            // always tell the output the current orientation
            self.orientationObserver.$captureVideoOrientation.sink { [weak self] videoOrientation in
                self?.sessionQueue.async {
                    self?.videoDataOutput.connection(with: .video)?.videoOrientation = videoOrientation
                }
            }.store(in: &self.subscriptions)
            #endif
        } else {
            assertionFailure("Could not add video data output to the session")
            return
        }
    }


    // MARK: Capture

    func startCapturing() {
        #if !targetEnvironment(simulator)
        self.sessionQueue.async {
            self.captureSession.startRunning()
        }
        #endif
    }

    func stopCapturing() {
        self.sessionQueue.async {
            self.captureSession.stopRunning()
        }
    }

}


/// Helper for getting camera frames from the `AVCaptureVideoDataOutput` and passing them
/// to the `previewPixelBufferProvider`.
private class PreviewPixelBufferDelegate: NSObject, AVCaptureVideoDataOutputSampleBufferDelegate {

    let previewPixelBufferProvider: PreviewPixelBufferProvider

    init(previewPixelBufferProvider: PreviewPixelBufferProvider) {
        self.previewPixelBufferProvider = previewPixelBufferProvider
    }

    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }
        // pass new frames in the main thread since this is the interface to SwiftUI
        DispatchQueue.main.async {
            self.previewPixelBufferProvider.previewPixelBuffer = pixelBuffer
        }
    }

}
