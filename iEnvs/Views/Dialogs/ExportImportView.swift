//
//  ExportImportView.swift
//  iEnvs
//
//  Created on 2026-02-08.
//

import SwiftUI
import AppKit

struct ExportImportView: View {
    @EnvironmentObject var viewModel: EnvGroupViewModel
    @Binding var isPresented: Bool

    @State private var exportIncludesDisabled: Bool = false
    @State private var showingExportResult: Bool = false
    @State private var showingImportResult: Bool = false
    @State private var resultMessage: String = ""
    @State private var isProcessing: Bool = false

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("导入/导出")
                    .font(.title2)
                    .fontWeight(.bold)

                Spacer()

                Button(action: { isPresented = false }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(.secondary)
                        .font(.title3)
                }
                .buttonStyle(.plain)
            }
            .padding()

            Divider()

            // Content
            ScrollView {
                VStack(spacing: 24) {
                    // Export section
                    exportSection

                    Divider()

                    // Import section
                    importSection
                }
                .padding()
            }

            Divider()

            // Footer
            HStack {
                Spacer()

                Button("关闭") {
                    isPresented = false
                }
                .keyboardShortcut(.cancelAction)
            }
            .padding()
        }
        .frame(width: 500, height: 400)
        .alert("操作结果", isPresented: Binding(
            get: { showingExportResult || showingImportResult },
            set: { if !$0 { showingExportResult = false; showingImportResult = false } }
        )) {
            Button("确定", role: .cancel) {}
        } message: {
            Text(resultMessage)
        }
    }

    // MARK: - Export Section

    private var exportSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "square.and.arrow.up")
                    .font(.title2)
                    .foregroundStyle(.blue)

                Text("导出")
                    .font(.title3)
                    .fontWeight(.semibold)
            }

            Text("将环境变量分组导出为 JSON 文件")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            Toggle(isOn: $exportIncludesDisabled) {
                Text("包含已禁用的分组")
                    .font(.body)
            }
            .toggleStyle(.checkbox)
            .padding(.vertical, 4)

            Button(action: exportToJSON) {
                Label("导出为 JSON", systemImage: "doc.text")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .disabled(isProcessing)
        }
        .padding()
        .background(Color(nsColor: .controlBackgroundColor))
        .cornerRadius(12)
    }

    // MARK: - Import Section

    private var importSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "square.and.arrow.down")
                    .font(.title2)
                    .foregroundStyle(.green)

                Text("导入")
                    .font(.title3)
                    .fontWeight(.semibold)
            }

            Text("从 JSON 文件导入环境变量分组")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Image(systemName: "info.circle")
                        .foregroundStyle(.secondary)

                    Text("导入时的处理规则:")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text("• 如果分组名已存在，将提示选择操作")
                    Text("• 导入的分组默认为禁用状态")
                    Text("• 将保留原有分组的顺序")
                }
                .font(.caption)
                .foregroundStyle(.tertiary)
                .padding(.leading, 24)
            }
            .padding(.vertical, 4)

            Button(action: importFromJSON) {
                Label("从 JSON 导入", systemImage: "doc.badge.plus")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .tint(.green)
            .disabled(isProcessing)
        }
        .padding()
        .background(Color(nsColor: .controlBackgroundColor))
        .cornerRadius(12)
    }

    // MARK: - Actions

    private func exportToJSON() {
        isProcessing = true

        // Open save panel
        let savePanel = NSSavePanel()
        savePanel.allowedContentTypes = [.json]
        savePanel.nameFieldStringValue = "ienvs-export-\(Date.filenameSafeString).json"
        savePanel.title = "导出环境变量"
        savePanel.message = "选择导出文件的保存位置"

        savePanel.begin { response in
            defer { isProcessing = false }

            guard response == .OK, let url = savePanel.url else {
                return
            }

            do {
                let groupsToExport = exportIncludesDisabled
                    ? viewModel.groups
                    : viewModel.groups.filter { $0.isEnabled }

                let exportData = ExportData(version: "1.0", exportDate: Date(), groups: groupsToExport)
                let encoder = JSONEncoder()
                encoder.dateEncodingStrategy = .iso8601
                encoder.outputFormatting = [.prettyPrinted, .sortedKeys]

                let data = try encoder.encode(exportData)
                try data.write(to: url)

                resultMessage = "成功导出 \(groupsToExport.count) 个分组到:\n\(url.path)"
                showingExportResult = true
            } catch {
                resultMessage = "导出失败:\n\(error.localizedDescription)"
                showingExportResult = true
            }
        }
    }

    private func importFromJSON() {
        isProcessing = true

        // Open file panel
        let openPanel = NSOpenPanel()
        openPanel.allowedContentTypes = [.json]
        openPanel.allowsMultipleSelection = false
        openPanel.title = "导入环境变量"
        openPanel.message = "选择要导入的 JSON 文件"

        openPanel.begin { response in
            defer { isProcessing = false }

            guard response == .OK, let url = openPanel.url else {
                return
            }

            do {
                let data = try Data(contentsOf: url)
                let decoder = JSONDecoder()
                decoder.dateDecodingStrategy = .iso8601

                let exportData = try decoder.decode(ExportData.self, from: data)

                // Process imported groups
                var importedCount = 0
                var skippedCount = 0
                let existingNames = Set(viewModel.groups.map { $0.name })

                for var group in exportData.groups {
                    if existingNames.contains(group.name) {
                        // Ask user for conflict resolution
                        let action = askForConflictResolution(groupName: group.name)

                        switch action {
                        case .skip:
                            skippedCount += 1
                            continue
                        case .rename:
                            group.name = generateUniqueName(
                                baseName: group.name,
                                existingNames: existingNames
                            )
                        case .overwrite:
                            // Remove existing group
                            if let existingGroup = viewModel.groups.first(where: { $0.name == group.name }) {
                                viewModel.deleteGroup(id: existingGroup.id)
                            }
                        }
                    }

                    // Create new group (disabled by default)
                    viewModel.addGroup(name: group.name, description: group.description)
                    // Add variables from imported group to the newly created group
                    if let newGroup = viewModel.groups.last {
                        for variable in group.variables {
                            viewModel.addVariable(to: newGroup.id, key: variable.key, value: variable.value)
                        }
                    }
                    importedCount += 1
                }

                resultMessage = "导入完成:\n成功导入 \(importedCount) 个分组"
                if skippedCount > 0 {
                    resultMessage += "\n跳过 \(skippedCount) 个分组"
                }
                showingImportResult = true
            } catch {
                resultMessage = "导入失败:\n\(error.localizedDescription)"
                showingImportResult = true
            }
        }
    }

    // MARK: - Helper Methods

    private func askForConflictResolution(groupName: String) -> ConflictResolution {
        let alert = NSAlert()
        alert.messageText = "分组名称冲突"
        alert.informativeText = "已存在名为「\(groupName)」的分组，请选择操作："
        alert.addButton(withTitle: "跳过")
        alert.addButton(withTitle: "重命名")
        alert.addButton(withTitle: "覆盖")
        alert.alertStyle = .warning

        let response = alert.runModal()

        switch response {
        case .alertFirstButtonReturn:
            return .skip
        case .alertSecondButtonReturn:
            return .rename
        case .alertThirdButtonReturn:
            return .overwrite
        default:
            return .skip
        }
    }

    private func generateUniqueName(baseName: String, existingNames: Set<String>) -> String {
        var counter = 1
        var newName = "\(baseName)-导入"

        while existingNames.contains(newName) {
            counter += 1
            newName = "\(baseName)-导入\(counter)"
        }

        return newName
    }
}

// MARK: - Supporting Types

enum ConflictResolution {
    case skip
    case rename
    case overwrite
}

// MARK: - Date Extension

extension Date {
    static var filenameSafeString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyyMMdd"
        return formatter.string(from: Date())
    }
}

// MARK: - Preview

#Preview {
    ExportImportView(isPresented: .constant(true))
        .environmentObject(EnvGroupViewModel())
}
