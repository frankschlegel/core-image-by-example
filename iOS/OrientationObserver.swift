import AVFoundation.AVCaptureSession
import Combine
import UIKit


/// Helper for monitoring device orientation changes, converting them into
/// `AVCaptureVideoOrientation`, and publishing those changes via Combine.
class OrientationObserver: ObservableObject {

    @Published private(set) var captureVideoOrientation: AVCaptureVideoOrientation

    private var cancellables = Set<AnyCancellable>()


    init() {
        UIDevice.current.beginGeneratingDeviceOrientationNotifications()

        self.captureVideoOrientation = getCurrentOrientation() ?? .portrait

        // register for device orientation changes and bind to `captureVideoOrientation`
        NotificationCenter.default.publisher(for: UIDevice.orientationDidChangeNotification)
            .receive(on: DispatchQueue.main)
            .compactMap({ _ in getCurrentOrientation() })
            .assign(to: \.captureVideoOrientation, on: self)
            .store(in: &cancellables)

        NotificationCenter.default.publisher(for: UIScene.didActivateNotification)
            .receive(on: DispatchQueue.main)
            .compactMap({ _ in getCurrentOrientation() })
            .assign(to: \.captureVideoOrientation, on: self)
            .store(in: &cancellables)
    }

    deinit {
        UIDevice.current.endGeneratingDeviceOrientationNotifications()
    }

}


private func getCurrentOrientation() -> AVCaptureVideoOrientation? {
    // get the current orientation from the device if available,
    // otherwise use the interface orientation of the main window
    var currentOrientation: AVCaptureVideoOrientation?
    func getOrientation() {
        if let currentVideoOrientation = AVCaptureVideoOrientation(deviceOrientation: UIDevice.current.orientation) {
            currentOrientation = currentVideoOrientation
        } else if let interfaceOrientation = UIApplication.shared.windows.first(where: { $0.isKeyWindow })?.windowScene?.interfaceOrientation,
                  let currentVideoOrientation = AVCaptureVideoOrientation(interfaceOrientation: interfaceOrientation) {
            currentOrientation = currentVideoOrientation
        }
    }

    // make sure to call the above in main thread
    if Thread.isMainThread {
        getOrientation()
    } else {
        DispatchQueue.main.sync(execute: getOrientation)
    }

    return currentOrientation
}


private extension AVCaptureVideoOrientation {

    init?(deviceOrientation: UIDeviceOrientation) {
        switch deviceOrientation {
            case .portrait: self = .portrait
            case .portraitUpsideDown: self = .portraitUpsideDown
            case .landscapeLeft: self = .landscapeRight
            case .landscapeRight: self = .landscapeLeft
            default: return nil
        }
    }

    init?(interfaceOrientation: UIInterfaceOrientation) {
        switch interfaceOrientation {
            case .portrait: self = .portrait
            case .portraitUpsideDown: self = .portraitUpsideDown
            case .landscapeLeft: self = .landscapeLeft
            case .landscapeRight: self = .landscapeRight
            default: return nil
        }
    }

}
