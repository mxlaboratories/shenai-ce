import ShenaiSDK
import UIKit

@main
class AppDelegate: UIResponder, UIApplicationDelegate {
    var window: UIWindow?

    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        window = UIWindow(frame: UIScreen.main.bounds)

        guard !CeConfig.apiKey.isEmpty else {
            showMessage("Set SHENAI_API_KEY and run the example again.")
            return true
        }

        let settings = InitializationSettings()
        settings.initializationMode = InitializationMode(rawValue: 0)!

        let result = ShenaiSDK.initialize(
            CeConfig.apiKey,
            userID: CeConfig.userId.isEmpty ? nil : CeConfig.userId,
            settings: settings
        )

        guard result == .success else {
            showMessage("Shen.AI initialization failed: \(result.rawValue)")
            return true
        }

        ShenaiSDK.setLanguage(CeConfig.language)
        window?.rootViewController = ShenaiView()
        window?.makeKeyAndVisible()
        return true
    }

    func applicationWillTerminate(_ application: UIApplication) {
        ShenaiSDK.deinitialize()
    }
    private func showMessage(_ message: String) {
        let controller = UIViewController()
        controller.view.backgroundColor = .systemBackground

        let label = UILabel()
        label.text = message
        label.textAlignment = .center
        label.numberOfLines = 0
        label.translatesAutoresizingMaskIntoConstraints = false

        controller.view.addSubview(label)
        NSLayoutConstraint.activate([
            label.leadingAnchor.constraint(equalTo: controller.view.leadingAnchor, constant: 24),
            label.trailingAnchor.constraint(equalTo: controller.view.trailingAnchor, constant: -24),
            label.centerYAnchor.constraint(equalTo: controller.view.centerYAnchor),
        ])

        window?.rootViewController = controller
        window?.makeKeyAndVisible()
    }
}
