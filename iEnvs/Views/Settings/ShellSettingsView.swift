import SwiftUI

struct ShellSettingsView: View {
    @ObservedObject var viewModel: SettingsViewModel

    var body: some View {
        Form {
            Section {
                VStack(alignment: .leading, spacing: 20) {
                    // Detected shell info
                    detectedShellSection

                    Divider()

                    // Shell type picker
                    shellTypeSection

                    Divider()

                    // Config file path
                    configPathSection

                    Divider()

                    // Auto detect button
                    autoDetectSection
                }
                .padding()
            }
        }
        .formStyle(.grouped)
    }

    // MARK: - Detected Shell Section

    private var detectedShellSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(L10n.Settings.detectedShell)
                .font(.headline)

            HStack(spacing: 8) {
                Image(systemName: "terminal.fill")
                    .foregroundStyle(.secondary)

                Text(viewModel.detectedShellType.displayName)
                    .font(.body)
                    .fontWeight(.medium)

                Spacer()

                Text(L10n.Settings.detected)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.green.opacity(0.1))
                    .cornerRadius(4)
            }
            .padding()
            .background(Color(nsColor: .controlBackgroundColor))
            .cornerRadius(8)
        }
    }

    // MARK: - Shell Type Section

    private var shellTypeSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(L10n.Settings.shellType)
                .font(.headline)

            Picker(L10n.Settings.selectShell, selection: $viewModel.settings.shellType) {
                ForEach(ShellType.allCases) { type in
                    HStack {
                        Image(systemName: "terminal")
                        Text(type.displayName)
                    }
                    .tag(type)
                }
            }
            .pickerStyle(.radioGroup)

            Text(L10n.Settings.shellTypeChangeNote)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }

    // MARK: - Config Path Section

    private var configPathSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(L10n.Settings.configFilePath)
                .font(.headline)

            HStack {
                TextField(L10n.Settings.configFilePathPlaceholder, text: $viewModel.settings.configFilePath)
                    .textFieldStyle(.roundedBorder)
                    .font(.system(.body, design: .monospaced))
                    .disabled(true)

                Button(action: openConfigFileInFinder) {
                    Image(systemName: "arrow.right.circle")
                }
                .buttonStyle(.bordered)
                .help(L10n.Settings.showInFinder)
            }

            Text(L10n.Settings.configFileNote)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }

    // MARK: - Auto Detect Section

    private var autoDetectSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Button(action: {
                viewModel.autoDetectShell()
            }) {
                Label(L10n.Settings.autoDetectShell, systemImage: "arrow.clockwise")
            }
            .buttonStyle(.bordered)

            Text(L10n.Settings.autoDetectNote)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }

    // MARK: - Actions

    private func openConfigFileInFinder() {
        let url = URL(fileURLWithPath: viewModel.settings.configFilePath)
        NSWorkspace.shared.activateFileViewerSelecting([url])
    }
}

// MARK: - Preview

#Preview {
    ShellSettingsView(viewModel: SettingsViewModel())
        .frame(width: 600, height: 400)
}
