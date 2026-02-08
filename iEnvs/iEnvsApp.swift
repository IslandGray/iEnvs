import SwiftUI

@main
struct iEnvsApp: App {
    @StateObject private var viewModel = EnvGroupViewModel()

    var body: some Scene {
        WindowGroup {
            MainView()
                .environmentObject(viewModel)
                .frame(minWidth: 800, minHeight: 500)
        }
        .defaultSize(width: 1000, height: 650)

        Settings {
            SettingsView()
        }
    }
}
