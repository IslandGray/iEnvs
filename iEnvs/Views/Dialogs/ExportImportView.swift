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
                Text(L10n.Export.title)
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

                Button(L10n.General.close) {
                    isPresented = false
                }
                .keyboardShortcut(.cancelAction)
            }
            .padding()
        }
        .frame(width: 500, height: 400)
        .alert(L10n.Export.operationResult, isPresented: Binding(
            get: { showingExportResult || showingImportResult },
            set: { if !$0 { showingExportResult = false; showingImportResult = false } }
        )) {
            Button(L10n.General.ok, role: .cancel) {}
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

                Text(L10n.Export.exportTitle)
                    .font(.title3)
                    .fontWeight(.semibold)
            }

            Text(L10n.Export.exportDesc)
                .font(.subheadline)
                .foregroundStyle(.secondary)

            Toggle(isOn: $exportIncludesDisabled) {
                Text(L10n.Export.includeDisabled)
                    .font(.body)
            }
            .toggleStyle(.checkbox)
            .padding(.vertical, 4)

            Button(action: exportToJSON) {
                Label(L10n.Export.exportJSON, systemImage: "doc.text")
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

                Text(L10n.Export.importTitle)
                    .font(.title3)
                    .fontWeight(.semibold)
            }

            Text(L10n.Export.importDesc)
                .font(.subheadline)
                .foregroundStyle(.secondary)

            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Image(systemName: "info.circle")
                        .foregroundStyle(.secondary)

                    Text(L10n.Export.importRules)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text("• \(L10n.Export.importRule1)")
                    Text("• \(L10n.Export.importRule2)")
                    Text("• \(L10n.Export.importRule3)")
                }
                .font(.caption)
                .foregroundStyle(.tertiary)
                .padding(.leading, 24)
            }
            .padding(.vertical, 4)

            Button(action: importFromJSON) {
                Label(L10n.Export.importJSON, systemImage: "doc.badge.plus")
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
        savePanel.title = L10n.Export.exportDialogTitle
        savePanel.message = L10n.Export.exportDialogMessage

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

                resultMessage = L10n.Export.exportSuccess(count: groupsToExport.count, path: url.path)
                showingExportResult = true
            } catch {
                resultMessage = L10n.Export.exportFailed(error.localizedDescription)
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
        openPanel.title = L10n.Export.importDialogTitle
        openPanel.message = L10n.Export.importDialogMessage

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

                resultMessage = L10n.Export.importSuccess(count: importedCount)
                if skippedCount > 0 {
                    resultMessage += "\n" + L10n.Export.importSkipped(skippedCount)
                }
                showingImportResult = true
            } catch {
                resultMessage = L10n.Export.importFailed(error.localizedDescription)
                showingImportResult = true
            }
        }
    }

    // MARK: - Helper Methods

    private func askForConflictResolution(groupName: String) -> ConflictResolution {
        let alert = NSAlert()
        alert.messageText = L10n.Export.conflictTitle
        alert.informativeText = L10n.Export.conflictMessage(groupName)
        alert.addButton(withTitle: L10n.Export.skip)
        alert.addButton(withTitle: L10n.General.rename)
        alert.addButton(withTitle: L10n.Export.overwrite)
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
        var newName = L10n.Export.importSuffix(baseName)

        while existingNames.contains(newName) {
            counter += 1
            newName = L10n.Export.importSuffixN(baseName, counter)
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
