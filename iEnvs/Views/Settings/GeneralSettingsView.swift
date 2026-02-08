//
//  GeneralSettingsView.swift
//  iEnvs
//
//  Created on 2026-02-08.
//

import SwiftUI

struct GeneralSettingsView: View {
    @ObservedObject var viewModel: SettingsViewModel

    var body: some View {
        Form {
            Section {
                VStack(alignment: .leading, spacing: 20) {
                    // Theme selection
                    themeSection

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
            Text("外观")
                .font(.headline)

            Picker("主题", selection: $viewModel.settings.theme) {
                ForEach(ThemeMode.allCases) { theme in
                    Text(theme.displayName).tag(theme)
                }
            }
            .pickerStyle(.segmented)
            .frame(width: 300)

            Text("注意: macOS 应用主题跟随系统设置")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }

    // MARK: - Conflict Detection Section

    private var conflictDetectionSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("冲突检测")
                .font(.headline)

            Toggle(isOn: $viewModel.settings.enableConflictDetection) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("启用冲突检测")
                        .font(.body)

                    Text("检测跨分组的变量名冲突并显示警告")
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
            Text("导出设置")
                .font(.headline)

            Toggle(isOn: $viewModel.settings.exportIncludesDisabledGroups) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("导出时包含禁用的分组")
                        .font(.body)

                    Text("导出 JSON 时是否包含未启用的分组")
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
