import CoreImage
import Combine


/// Very simple controller for transforming incoming `CVPixelBuffer`s into
/// filtered `CIImage`s – all via Combine publishers.
class FilterController {

    let filteredImagePublisher: AnyPublisher<CIImage?, Never>

    private let filter = CIFilter(name: "CIComicEffect")!


    init(pixelBufferPublisher: AnyPublisher<CVPixelBuffer?, Never>) {
        self.filteredImagePublisher = pixelBufferPublisher
            // transform the pixel buffer into an `CIImage`...
            .map { $0.flatMap({ CIImage(cvPixelBuffer: $0) }) }
            // ... apply the filter to it...
            .map { [weak filter = self.filter] inputImage -> CIImage? in
                filter?.setValue(inputImage, forKey: kCIInputImageKey)
                return filter?.outputImage
            }
            .eraseToAnyPublisher()
    }

}
