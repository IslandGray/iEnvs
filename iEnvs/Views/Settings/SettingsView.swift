import SwiftUI

struct SettingsView: View {
    @StateObject private var settingsVM = SettingsViewModel()
    @ObservedObject var localization = LocalizationManager.shared

    var body: some View {
        TabView {
            GeneralSettingsView(viewModel: settingsVM)
                .tabItem {
                    Label(L10n.Settings.general, systemImage: "gearshape")
                }
                .tag(0)

            ShellSettingsView(viewModel: settingsVM)
                .tabItem {
                    Label(L10n.Settings.shell, systemImage: "terminal")
                }
                .tag(1)

            BackupSettingsView(viewModel: settingsVM)
                .tabItem {
                    Label(L10n.Settings.backup, systemImage: "clock.arrow.circlepath")
                }
                .tag(2)
        }
        .frame(width: 600, height: 400)
        .onChange(of: settingsVM.settings) { _ in
            settingsVM.saveSettings()
        }
        .onChange(of: settingsVM.settings.theme) { newTheme in
            NSApp.appearance = newTheme.nsAppearance
        }
    }
}

// MARK: - Preview

#Preview {
    SettingsView()
}
