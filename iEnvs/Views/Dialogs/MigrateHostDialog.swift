import SwiftUI

struct MigrateHostDialog: View {
    @Binding var isPresented: Bool
    let host: (entry: HostEntry, lineNumber: Int)
    @Binding var newIp: String
    @Binding var newHostname: String
    let groups: [HostGroup]
    let onMigrate: (UUID?, String?) -> Void

    @State private var selectedGroupId: UUID? = nil
    @State private var createNewGroup = false
    @State private var newGroupName: String = ""

    var body: some View {
        VStack(spacing: 20) {
            // Header
            HStack {
                Image(systemName: "arrow.right.circle.fill")
                    .font(.title2)
                    .foregroundStyle(.blue)

                Text(L10n.Migrate.hostsTitle)
                    .font(.title3)
                    .fontWeight(.semibold)

                Spacer()
            }

            // Warning message
            HStack(alignment: .top, spacing: 8) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundStyle(.orange)

                Text(L10n.Migrate.hostsWarningMessage)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(12)
            .background(Color.orange.opacity(0.1))
            .cornerRadius(8)

            // Host info
            VStack(alignment: .leading, spacing: 12) {
                // Current values
                HStack {
                    Text(L10n.Migrate.currentIpLabel)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    Spacer()
                    Text(host.entry.ip)
                        .font(.system(.body, design: .monospaced))
                        .foregroundStyle(.secondary)
                }

                HStack {
                    Text(L10n.Migrate.currentHostnameLabel)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    Spacer()
                    Text(host.entry.hostname)
                        .font(.system(.body, design: .monospaced))
                        .foregroundStyle(.secondary)
                }

                if !host.entry.comment.isEmpty {
                    HStack {
                        Text(L10n.Migrate.currentCommentLabel)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                        Spacer()
                        Text(host.entry.comment)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                            .truncationMode(.tail)
                    }
                }

                Divider()

                // New values
                VStack(alignment: .leading, spacing: 6) {
                    Text(L10n.Migrate.newIpLabel)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)

                    TextField("", text: $newIp)
                        .textFieldStyle(.roundedBorder)
                        .font(.system(.body, design: .monospaced))
                }

                VStack(alignment: .leading, spacing: 6) {
                    Text(L10n.Migrate.newHostnameLabel)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)

                    TextField("", text: $newHostname)
                        .textFieldStyle(.roundedBorder)
                        .font(.system(.body, design: .monospaced))
                }
            }
            .padding(12)
            .background(Color(nsColor: .controlBackgroundColor))
            .cornerRadius(8)

            // Group selection
            VStack(alignment: .leading, spacing: 12) {
                Text(L10n.Migrate.targetGroupLabel)
                    .font(.subheadline)
                    .fontWeight(.medium)

                if groups.isEmpty {
                    // No existing groups, force create new
                    Toggle(isOn: .constant(true)) {
                        Text(L10n.Migrate.createNewGroup)
                    }
                    .toggleStyle(.checkbox)
                    .disabled(true)

                    TextField(L10n.Migrate.newGroupNamePlaceholder, text: $newGroupName)
                        .textFieldStyle(.roundedBorder)
                } else {
                    Toggle(isOn: $createNewGroup) {
                        Text(L10n.Migrate.createNewGroup)
                    }
                    .toggleStyle(.checkbox)

                    if createNewGroup {
                        TextField(L10n.Migrate.newGroupNamePlaceholder, text: $newGroupName)
                            .textFieldStyle(.roundedBorder)
                    } else {
                        Picker(L10n.Migrate.selectGroup, selection: $selectedGroupId) {
                            Text(L10n.Migrate.selectGroupPrompt).tag(nil as UUID?)
                            ForEach(groups) { group in
                                Text(group.name).tag(group.id as UUID?)
                            }
                        }
                        .pickerStyle(.menu)
                        .labelsHidden()
                    }
                }
            }

            Spacer()

            // Buttons
            HStack {
                Button(L10n.General.cancel) {
                    isPresented = false
                }
                .keyboardShortcut(.cancelAction)

                Spacer()

                Button(L10n.Migrate.confirmButton) {
                    let targetId = createNewGroup ? nil : selectedGroupId
                    let newName = createNewGroup ? (newGroupName.isEmpty ? nil : newGroupName) : nil
                    onMigrate(targetId, newName)
                    isPresented = false
                }
                .keyboardShortcut(.defaultAction)
                .disabled(!canMigrate)
            }
        }
        .padding()
        .frame(width: 450, height: 550)
    }

    private var canMigrate: Bool {
        if groups.isEmpty || createNewGroup {
            return !newGroupName.isEmpty && !newIp.isEmpty && !newHostname.isEmpty
        } else {
            return selectedGroupId != nil && !newIp.isEmpty && !newHostname.isEmpty
        }
    }
}

// MARK: - Preview

#Preview {
    MigrateHostDialog(
        isPresented: .constant(true),
        host: (
            entry: HostEntry(
                ip: "127.0.0.1",
                hostname: "localhost",
                comment: "local",
                isEnabled: true
            ),
            lineNumber: 10
        ),
        newIp: .constant("127.0.0.1"),
        newHostname: .constant("localhost"),
        groups: [],
        onMigrate: { _, _ in }
    )
}
