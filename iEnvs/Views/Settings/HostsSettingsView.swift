import SwiftUI

struct HostsSettingsView: View {
    private let hostsFileManager = HostsFileManager()
    @State private var flushResult: String?

    var body: some View {
        Form {
            // Hosts file info
            Section {
                LabeledContent(L10n.Hosts.hostsFilePath) {
                    HStack {
                        Text(Constants.HostsMarkers.hostsFilePath)
                            .font(.system(.body, design: .monospaced))
                            .textSelection(.enabled)

                        Button(L10n.Settings.showInFinder) {
                            NSWorkspace.shared.selectFile(
                                Constants.HostsMarkers.hostsFilePath,
                                inFileViewerRootedAtPath: "/etc"
                            )
                        }
                        .buttonStyle(.bordered)
                        .controlSize(.small)
                    }
                }

                LabeledContent(L10n.Hosts.filePermission) {
                    if hostsFileManager.isHostsFileReadable() {
                        Label(L10n.Hosts.permissionOK, systemImage: "checkmark.circle.fill")
                            .foregroundStyle(.green)
                    } else {
                        Label(L10n.Hosts.permissionError, systemImage: "xmark.circle.fill")
                            .foregroundStyle(.red)
                    }
                }
            }

            // DNS cache
            Section {
                VStack(alignment: .leading, spacing: 8) {
                    Text(L10n.Hosts.flushDNS)
                        .font(.headline)

                    Text(L10n.Hosts.flushDNSDesc)
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    HStack {
                        Button(L10n.Hosts.flushDNS) {
                            flushDNSCache()
                        }
                        .buttonStyle(.bordered)

                        if let result = flushResult {
                            Text(result)
                                .font(.caption)
                                .foregroundStyle(result == L10n.Hosts.flushDNSSuccess ? .green : .red)
                        }
                    }
                }
            }

            // Info
            Section {
                VStack(alignment: .leading, spacing: 4) {
                    Text(L10n.Hosts.adminRequired)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .formStyle(.grouped)
        .padding()
    }

    private func flushDNSCache() {
        do {
            try hostsFileManager.flushDNSCache()
            flushResult = L10n.Hosts.flushDNSSuccess
        } catch {
            flushResult = L10n.Hosts.flushDNSFailed
        }

        // 自动清除结果提示
        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
            flushResult = nil
        }
    }
}
