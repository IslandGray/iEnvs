//
//  ShellSettingsView.swift
//  iEnvs
//
//  Created on 2026-02-08.
//

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
            Text("当前检测到的 Shell")
                .font(.headline)

            HStack(spacing: 8) {
                Image(systemName: "terminal.fill")
                    .foregroundStyle(.secondary)

                Text(viewModel.detectedShellType.displayName)
                    .font(.body)
                    .fontWeight(.medium)

                Spacer()

                Text("已检测")
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
            Text("Shell 类型")
                .font(.headline)

            Picker("选择 Shell", selection: $viewModel.settings.shellType) {
                ForEach(ShellType.allCases) { type in
                    HStack {
                        Image(systemName: "terminal")
                        Text(type.displayName)
                    }
                    .tag(type)
                }
            }
            .pickerStyle(.radioGroup)

            Text("更改 Shell 类型将自动更新配置文件路径")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }

    // MARK: - Config Path Section

    private var configPathSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("配置文件路径")
                .font(.headline)

            HStack {
                TextField("配置文件路径", text: $viewModel.settings.configFilePath)
                    .textFieldStyle(.roundedBorder)
                    .font(.system(.body, design: .monospaced))
                    .disabled(true)

                Button(action: openConfigFileInFinder) {
                    Image(systemName: "arrow.right.circle")
                }
                .buttonStyle(.bordered)
                .help("在 Finder 中显示")
            }

            Text("配置文件将在此位置写入环境变量")
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
                Label("自动检测 Shell", systemImage: "arrow.clockwise")
            }
            .buttonStyle(.bordered)

            Text("重新检测系统默认 Shell 并更新配置")
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
