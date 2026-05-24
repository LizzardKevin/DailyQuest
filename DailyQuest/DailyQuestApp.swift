import SwiftUI
import SwiftData

@main
struct DailyQuestApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate

    private let modelContainer = ModelContainerFactory.make()

    var body: some Scene {
        WindowGroup {
            RootView()
                .onAppear {
                    let mode = AppearanceMode.load()
                    UserDefaults.standard.set(mode.rawValue, forKey: "dailyquest.appearanceMode")
                }
        }
        .modelContainer(modelContainer)
    }
}

final class AppDelegate: NSObject, UIApplicationDelegate {
    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
        NotificationService.shared.registerCategories()
        return true
    }
}
