import SwiftUI

struct HostsExportImportView: View {
    @Binding var isPresented: Bool
    @EnvironmentObject var viewModel: HostsGroupViewModel
    @State private var includeDisabled: Bool = true
    @State private var resultMessage: String?

    var body: some View {
        VStack(spacing: 20) {
            // Header
            Text(L10n.Hosts.exportImport)
                .font(.title2)
                .bold()

            // Export Section
            GroupBox {
                VStack(alignment: .leading, spacing: 12) {
                    Text(L10n.Hosts.exportTitle)
                        .font(.headline)

                    Text(L10n.Hosts.exportDesc)
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    Toggle(L10n.Export.includeDisabled, isOn: $includeDisabled)
                        .toggleStyle(.checkbox)

                    HStack(spacing: 12) {
                        Button(L10n.Hosts.exportAsJSON) {
                            exportJSON()
                        }
                        .buttonStyle(.bordered)

                        Button(L10n.Hosts.exportAsHosts) {
                            exportHostsFormat()
                        }
                        .buttonStyle(.bordered)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(4)
            }

            // Import Section
            GroupBox {
                VStack(alignment: .leading, spacing: 12) {
                    Text(L10n.Hosts.importTitle)
                        .font(.headline)

                    Text(L10n.Hosts.importDesc)
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    HStack(spacing: 12) {
                        Button(L10n.Hosts.importFromJSON) {
                            importJSON()
                        }
                        .buttonStyle(.bordered)

                        Button(L10n.Hosts.importFromHosts) {
                            importHostsFile()
                        }
                        .buttonStyle(.bordered)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(4)
            }

            // Result message
            if let message = resultMessage {
                Text(message)
                    .font(.callout)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.secondary.opacity(0.1))
                    .cornerRadius(8)
            }

            // Close button
            HStack {
                Spacer()
                Button(L10n.General.close) {
                    isPresented = false
                }
                .keyboardShortcut(.cancelAction)
            }
        }
        .padding(24)
        .frame(width: 500)
    }

    // MARK: - Export Actions

    private func exportJSON() {
        let groups = includeDisabled
            ? viewModel.hostsGroups
            : viewModel.hostsGroups.filter { $0.isEnabled }

        let data = HostsImportExportManager.exportToJSON(groups: groups)

        let panel = NSSavePanel()
        panel.allowedContentTypes = [.json]
        panel.nameFieldStringValue = "iEnvs-hosts-export.json"

        if panel.runModal() == .OK, let url = panel.url {
            do {
                try data.write(to: url)
                resultMessage = L10n.Export.exportSuccess(count: groups.count, path: url.path)
            } catch {
                resultMessage = L10n.Export.exportFailed(error.localizedDescription)
            }
        }
    }

    private func exportHostsFormat() {
        let groups = includeDisabled
            ? viewModel.hostsGroups
            : viewModel.hostsGroups.filter { $0.isEnabled }

        let content = HostsImportExportManager.exportToHostsFormat(groups: groups)

        let panel = NSSavePanel()
        panel.allowedContentTypes = [.plainText]
        panel.nameFieldStringValue = "iEnvs-hosts-export.txt"

        if panel.runModal() == .OK, let url = panel.url {
            do {
                try content.write(to: url, atomically: true, encoding: .utf8)
                resultMessage = L10n.Export.exportSuccess(count: groups.count, path: url.path)
            } catch {
                resultMessage = L10n.Export.exportFailed(error.localizedDescription)
            }
        }
    }

    // MARK: - Import Actions

    private func importJSON() {
        let panel = NSOpenPanel()
        panel.allowedContentTypes = [.json]
        panel.allowsMultipleSelection = false

        if panel.runModal() == .OK, let url = panel.url {
            do {
                let data = try Data(contentsOf: url)
                guard let groups = HostsImportExportManager.importFromJSON(data: data) else {
                    resultMessage = L10n.Export.importFailed("Invalid format")
                    return
                }

                viewModel.importGroups(groups)
                resultMessage = L10n.Export.importSuccess(count: groups.count)
            } catch {
                resultMessage = L10n.Export.importFailed(error.localizedDescription)
            }
        }
    }

    private func importHostsFile() {
        let panel = NSOpenPanel()
        panel.allowedContentTypes = [.plainText]
        panel.allowsMultipleSelection = false

        if panel.runModal() == .OK, let url = panel.url {
            do {
                let content = try String(contentsOf: url, encoding: .utf8)
                let groupName = url.deletingPathExtension().lastPathComponent
                let group = HostsImportExportManager.importFromHostsFormat(
                    content: content,
                    groupName: groupName
                )

                viewModel.importGroups([group])
                resultMessage = L10n.Export.importSuccess(count: 1)
            } catch {
                resultMessage = L10n.Export.importFailed(error.localizedDescription)
            }
        }
    }
}
