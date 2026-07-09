import UIKit

final class SceneDelegate: UIResponder, UIWindowSceneDelegate {
    var window: UIWindow?

    func scene(
        _ scene: UIScene,
        willConnectTo session: UISceneSession,
        options connectionOptions: UIScene.ConnectionOptions
    ) {
        guard let windowScene = scene as? UIWindowScene else { return }

        #if targetEnvironment(macCatalyst)
        // A tall, phone-ish window suits a vertical board better than the
        // default 1024x768 iPad shape.
        windowScene.sizeRestrictions?.minimumSize = CGSize(width: 480, height: 640)
        windowScene.titlebar?.titleVisibility = .hidden
        windowScene.titlebar?.toolbar = nil
        #endif

        let window = UIWindow(windowScene: windowScene)
        window.rootViewController = GameViewController()
        window.makeKeyAndVisible()
        self.window = window
    }
}
