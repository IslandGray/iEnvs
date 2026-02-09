import SwiftUI

struct GeneralSettingsView: View {
    @ObservedObject var viewModel: SettingsViewModel
    @ObservedObject var localization = LocalizationManager.shared

    var body: some View {
        Form {
            Section {
                VStack(alignment: .leading, spacing: 20) {
                    // Theme selection
                    themeSection

                    Divider()

                    // Language selection
                    languageSection

                    Divider()

                    // Conflict detection
                    conflictDetectionSection

                    Divider()

                    // Export settings
                    exportSettingsSection
                }
                .padding()
            }
        }
        .formStyle(.grouped)
    }

    // MARK: - Theme Section

    private var themeSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(L10n.Settings.appearance)
                .font(.headline)

            Picker(L10n.Settings.theme, selection: $viewModel.settings.theme) {
                ForEach(ThemeMode.allCases) { theme in
                    Text(theme.displayName).tag(theme)
                }
            }
            .pickerStyle(.segmented)
            .frame(width: 300)

            Text(L10n.Settings.themeNote)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }

    // MARK: - Language Section

    private var languageSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(L10n.Settings.language)
                .font(.headline)

            Picker(L10n.Settings.languagePicker, selection: Binding(
                get: { localization.language },
                set: { newLang in
                    localization.setLanguage(newLang)
                    viewModel.settings.language = newLang
                    viewModel.saveSettings()
                }
            )) {
                ForEach(AppLanguage.allCases) { lang in
                    Text(lang.displayName).tag(lang)
                }
            }
            .pickerStyle(.segmented)
            .frame(width: 300)
        }
    }

    // MARK: - Conflict Detection Section

    private var conflictDetectionSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(L10n.Settings.conflictDetection)
                .font(.headline)

            Toggle(isOn: $viewModel.settings.enableConflictDetection) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(L10n.Settings.enableConflictDetection)
                        .font(.body)

                    Text(L10n.Settings.conflictDetectionDesc)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .toggleStyle(.checkbox)
        }
    }

    // MARK: - Export Settings Section

    private var exportSettingsSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(L10n.Settings.exportSettings)
                .font(.headline)

            Toggle(isOn: $viewModel.settings.exportIncludesDisabledGroups) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(L10n.Settings.exportIncludeDisabled)
                        .font(.body)

                    Text(L10n.Settings.exportIncludeDisabledDesc)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .toggleStyle(.checkbox)
        }
    }
}

// MARK: - Preview

#Preview {
    GeneralSettingsView(viewModel: SettingsViewModel())
        .frame(width: 600, height: 400)
}
