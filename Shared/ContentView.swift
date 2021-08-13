import SwiftUI


struct ContentView: View {

    private let cameraController = CameraController()
    private let filterController: FilterController

    init() {
        // the `filterController` will transform camera frames into filtered images
        self.filterController = FilterController(pixelBufferPublisher: self.cameraController.previewPixelBufferProvider.$previewPixelBuffer.eraseToAnyPublisher())
    }


    var body: some View {
        PreviewView(imagePublisher: self.filterController.filteredImagePublisher)
            .onAppear {
                self.cameraController.startCapturing()
            }
            .onDisappear {
                self.cameraController.stopCapturing()
            }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
