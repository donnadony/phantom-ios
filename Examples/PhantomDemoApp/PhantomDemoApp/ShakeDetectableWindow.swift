import UIKit
import SwiftUI
import Phantom

final class ShakeDetectableWindow: UIWindow {

    override func motionEnded(_ motion: UIEvent.EventSubtype, with event: UIEvent?) {
        guard motion == .motionShake else { return }
        presentPhantom()
    }

    private func presentPhantom() {
        let phantomView = PhantomView()
            .environment(\.phantomTheme, Phantom.theme)
        let hostingController = UIHostingController(rootView: phantomView)
        hostingController.modalPresentationStyle = .fullScreen

        guard let rootVC = rootViewController,
              rootVC.presentedViewController == nil else { return }
        rootVC.present(hostingController, animated: true)
    }
}
