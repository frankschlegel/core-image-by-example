import SwiftUI


struct ContentView: View {

    private let cameraController = CameraController()


    var body: some View {
        PreviewView(previewPixelBufferProvider: self.cameraController.previewPixelBufferProvider)
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
