import SwiftUI

struct EditHostEntrySheet: View {
    let group: HostGroup
    let entry: HostEntry
    @Binding var isPresented: Bool
    @EnvironmentObject var viewModel: HostsGroupViewModel

    @State private var ip: String = ""
    @State private var hostname: String = ""
    @State private var comment: String = ""
    @State private var errorMessage: String?

    private var isIPValid: Bool {
        HostsValidators.validateIP(ip)
    }

    private var isHostnameValid: Bool {
        HostsValidators.validateHostname(hostname)
    }

    private var hostnameAlreadyExists: Bool {
        // 排除当前条目本身，检查是否有其他同名主机名
        group.entries.contains { $0.hostname == hostname && $0.id != entry.id }
    }

    private var canSave: Bool {
        !ip.isEmpty && isIPValid && !hostname.isEmpty && isHostnameValid && !hostnameAlreadyExists
    }

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text(L10n.Hosts.editEntryTitle)
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
                VStack(spacing: 20) {
                    // IP input
                    VStack(alignment: .leading, spacing: 6) {
                        Text(L10n.Hosts.ipAddress)
                            .font(.headline)

                        TextField(L10n.Hosts.ipPlaceholder, text: $ip)
                            .textFieldStyle(.roundedBorder)
                            .font(.system(.body, design: .monospaced))
                            .onChange(of: ip) { _ in
                                errorMessage = nil
                            }

                        if !ip.isEmpty {
                            HStack(spacing: 4) {
                                if isIPValid {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundStyle(.green)
                                    Text(L10n.Hosts.ipValid)
                                        .font(.caption)
                                        .foregroundStyle(.green)
                                } else {
                                    Image(systemName: "xmark.circle.fill")
                                        .foregroundStyle(.red)
                                    Text(L10n.Hosts.ipInvalid)
                                        .font(.caption)
                                        .foregroundStyle(.red)
                                }
                            }
                        }
                    }

                    // Hostname input
                    VStack(alignment: .leading, spacing: 6) {
                        Text(L10n.Hosts.hostname)
                            .font(.headline)

                        TextField(L10n.Hosts.hostnamePlaceholder, text: $hostname)
                            .textFieldStyle(.roundedBorder)
                            .font(.system(.body, design: .monospaced))
                            .onChange(of: hostname) { _ in
                                errorMessage = nil
                            }

                        if !hostname.isEmpty {
                            HStack(spacing: 4) {
                                if !isHostnameValid {
                                    Image(systemName: "xmark.circle.fill")
                                        .foregroundStyle(.red)
                                    Text(L10n.Hosts.hostnameInvalid)
                                        .font(.caption)
                                        .foregroundStyle(.red)
                                } else if hostnameAlreadyExists {
                                    Image(systemName: "xmark.circle.fill")
                                        .foregroundStyle(.red)
                                    Text(L10n.Hosts.hostnameExists)
                                        .font(.caption)
                                        .foregroundStyle(.red)
                                } else {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundStyle(.green)
                                    Text(L10n.Hosts.hostnameValid)
                                        .font(.caption)
                                        .foregroundStyle(.green)
                                }
                            }
                        }
                    }

                    // Comment input
                    VStack(alignment: .leading, spacing: 6) {
                        Text(L10n.Hosts.commentLabel)
                            .font(.headline)

                        TextField(L10n.Hosts.commentPlaceholder, text: $comment)
                            .textFieldStyle(.roundedBorder)
                    }

                    // Error message
                    if let error = errorMessage {
                        HStack {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundStyle(.red)
                            Text(error)
                                .font(.caption)
                                .foregroundStyle(.red)
                        }
                        .padding()
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color.red.opacity(0.1))
                        .cornerRadius(8)
                    }
                }
                .padding()
            }

            Divider()

            // Footer
            HStack {
                Spacer()

                Button(L10n.General.cancel) {
                    isPresented = false
                }
                .keyboardShortcut(.cancelAction)

                Button(L10n.General.save) {
                    saveEntry()
                }
                .keyboardShortcut(.defaultAction)
                .disabled(!canSave)
            }
            .padding()
        }
        .frame(width: 500, height: 350)
        .onAppear {
            // 初始化字段值
            ip = entry.ip
            hostname = entry.hostname
            comment = entry.comment
        }
    }

    private func saveEntry() {
        guard canSave else { return }
        viewModel.updateHostEntry(
            in: group.id,
            entryId: entry.id,
            ip: ip,
            hostname: hostname,
            comment: comment
        )
        isPresented = false
    }
}
