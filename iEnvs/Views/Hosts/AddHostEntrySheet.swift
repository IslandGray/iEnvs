import SwiftUI

struct AddHostEntrySheet: View {
    let group: HostGroup
    @Binding var isPresented: Bool
    @EnvironmentObject var viewModel: HostsGroupViewModel

    @State private var ip: String = ""
    @State private var hostname: String = ""
    @State private var comment: String = ""
    @State private var showBatchInput: Bool = false
    @State private var batchText: String = ""
    @State private var errorMessage: String?

    private var isIPValid: Bool {
        HostsValidators.validateIP(ip)
    }

    private var isHostnameValid: Bool {
        HostsValidators.validateHostname(hostname)
    }

    private var hostnameAlreadyExists: Bool {
        group.entries.contains { $0.hostname == hostname }
    }

    private var canSave: Bool {
        !ip.isEmpty && isIPValid && !hostname.isEmpty && isHostnameValid && !hostnameAlreadyExists
    }

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text(L10n.Hosts.addEntryTitle)
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
                    if showBatchInput {
                        batchInputView
                    } else {
                        singleInputView
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
                Toggle(isOn: $showBatchInput) {
                    Text(L10n.Hosts.batchImport)
                }
                .toggleStyle(.checkbox)
                .help(L10n.Hosts.batchImportHelp)

                Spacer()

                Button(L10n.General.cancel) {
                    isPresented = false
                }
                .keyboardShortcut(.cancelAction)

                Button(showBatchInput ? L10n.AddVariable.importButton : L10n.AddVariable.addButton) {
                    if showBatchInput {
                        saveBatchEntries()
                    } else {
                        saveEntry()
                    }
                }
                .keyboardShortcut(.defaultAction)
                .disabled(!canSave && !showBatchInput)
            }
            .padding()
        }
        .frame(width: 500, height: showBatchInput ? 400 : 350)
    }

    // MARK: - Single Input View

    private var singleInputView: some View {
        VStack(spacing: 16) {
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
        }
    }

    // MARK: - Batch Input View

    private var batchInputView: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(L10n.Hosts.batchImportTitle)
                .font(.headline)

            Text(L10n.Hosts.batchImportFormat)
                .font(.caption)
                .foregroundStyle(.secondary)

            TextEditor(text: $batchText)
                .font(.system(.body, design: .monospaced))
                .frame(minHeight: 200)
                .border(Color.secondary.opacity(0.3))
                .scrollContentBackground(.hidden)
                .background(Color(nsColor: .textBackgroundColor))

            Text("Example:\n127.0.0.1 dev.local # Dev server\n192.168.1.100 api.local\n10.0.0.1 db.local # Database")
                .font(.caption)
                .foregroundStyle(.tertiary)
                .padding(.top, 4)
        }
    }

    // MARK: - Actions

    private func saveEntry() {
        guard canSave else { return }
        viewModel.addHostEntry(to: group.id, ip: ip, hostname: hostname, comment: comment)
        isPresented = false
    }

    private func saveBatchEntries() {
        let lines = batchText.components(separatedBy: .newlines)
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty && !$0.hasPrefix("#") }

        var addedCount = 0
        var errors: [String] = []

        for line in lines {
            // 分离注释
            let commentSplit = line.components(separatedBy: "#")
            let mainPart = commentSplit[0].trimmingCharacters(in: .whitespaces)
            let lineComment = commentSplit.count > 1
                ? commentSplit.dropFirst().joined(separator: "#").trimmingCharacters(in: .whitespaces)
                : ""

            let parts = mainPart.split(separator: " ", omittingEmptySubsequences: true)
                .map { String($0) }

            guard parts.count >= 2 else {
                errors.append(L10n.AddVariable.formatError(line))
                continue
            }

            let lineIP = parts[0]
            let lineHostname = parts[1]

            guard HostsValidators.validateIP(lineIP) else {
                errors.append(L10n.Hosts.ipInvalid + ": \(lineIP)")
                continue
            }

            guard HostsValidators.validateHostname(lineHostname) else {
                errors.append(L10n.Hosts.hostnameInvalid + ": \(lineHostname)")
                continue
            }

            viewModel.addHostEntry(to: group.id, ip: lineIP, hostname: lineHostname, comment: lineComment)
            addedCount += 1
        }

        if errors.isEmpty {
            isPresented = false
        } else {
            errorMessage = L10n.AddVariable.batchResult(imported: addedCount, errors: errors)
        }
    }
}
