import SwiftUI

struct ExistingHostsView: View {
    @EnvironmentObject var viewModel: HostsGroupViewModel
    @Binding var isPresented: Bool

    @State private var showingMigrateDialog = false
    @State private var showingDeleteConfirmation = false
    @State private var selectedHost: (entry: HostEntry, lineNumber: Int)?
    @State private var editNewIp: String = ""
    @State private var editNewHostname: String = ""

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(L10n.Existing.hostsTitle)
                        .font(.title2)
                        .fontWeight(.bold)

                    Text(L10n.Existing.hostsSubtitle(viewModel.existingHosts.count))
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

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
            if viewModel.existingHosts.isEmpty {
                emptyStateView
            } else {
                listView
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
        .frame(width: 650, height: 500)
        .onAppear {
            viewModel.loadExistingHosts()
        }
        .sheet(isPresented: $showingMigrateDialog) {
            if let host = selectedHost {
                MigrateHostDialog(
                    isPresented: $showingMigrateDialog,
                    host: host,
                    newIp: $editNewIp,
                    newHostname: $editNewHostname,
                    groups: viewModel.hostsGroups,
                    onMigrate: { targetGroupId, newGroupName in
                        viewModel.migrateExistingHost(
                            host,
                            newIp: editNewIp.isEmpty ? nil : editNewIp,
                            newHostname: editNewHostname.isEmpty ? nil : editNewHostname,
                            targetGroupId: targetGroupId,
                            newGroupName: newGroupName
                        )
                    }
                )
            }
        }
        .alert(L10n.Existing.hostsDeleteConfirmTitle, isPresented: $showingDeleteConfirmation) {
            Button(L10n.General.cancel, role: .cancel) {}
            Button(L10n.General.delete, role: .destructive) {
                if let host = selectedHost {
                    viewModel.deleteExistingHost(host)
                }
            }
        } message: {
            if let host = selectedHost {
                Text(L10n.Existing.hostsDeleteConfirmMessage(host.entry.hostname))
            }
        }
    }

    // MARK: - Empty State

    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Image(systemName: "checkmark.circle")
                .font(.system(size: 48))
                .foregroundStyle(.secondary)

            Text(L10n.Existing.hostsEmptyTitle)
                .font(.title3)
                .fontWeight(.semibold)

            Text(L10n.Existing.hostsEmptyMessage)
                .font(.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(nsColor: .controlBackgroundColor))
    }

    // MARK: - List View

    private var listView: some View {
        List(viewModel.existingHosts, id: \.entry.id) { hostTuple in
            ExistingHostRow(
                host: hostTuple,
                onEdit: {
                    selectedHost = hostTuple
                    editNewIp = hostTuple.entry.ip
                    editNewHostname = hostTuple.entry.hostname
                    showingMigrateDialog = true
                },
                onDelete: {
                    selectedHost = hostTuple
                    showingDeleteConfirmation = true
                }
            )
        }
        .listStyle(.plain)
    }
}

// MARK: - Existing Host Row

struct ExistingHostRow: View {
    let host: (entry: HostEntry, lineNumber: Int)
    let onEdit: () -> Void
    let onDelete: () -> Void

    @State private var isHovering = false

    var body: some View {
        HStack(spacing: 12) {
            // IP
            VStack(alignment: .leading, spacing: 4) {
                Text(host.entry.ip)
                    .font(.system(.body, design: .monospaced))
                    .fontWeight(.medium)

                Text(L10n.Existing.lineNumber(host.lineNumber))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .frame(width: 120, alignment: .leading)

            // Hostname
            VStack(alignment: .leading, spacing: 4) {
                Text(host.entry.hostname)
                    .font(.system(.body, design: .monospaced))

                if !host.entry.comment.isEmpty {
                    Text("# \(host.entry.comment)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                        .truncationMode(.tail)
                }
            }

            Spacer()

            // Actions
            HStack(spacing: 8) {
                Button(action: onEdit) {
                    Label(L10n.Existing.editMigrate, systemImage: "arrow.right.circle")
                }
                .buttonStyle(.borderless)
                .foregroundStyle(.blue)

                Button(action: onDelete) {
                    Label(L10n.General.delete, systemImage: "trash")
                }
                .buttonStyle(.borderless)
                .foregroundStyle(.red)
            }
            .opacity(isHovering ? 1 : 0)
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
        .background(isHovering ? Color(nsColor: .selectedControlColor).opacity(0.3) : Color.clear)
        .cornerRadius(6)
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.15)) {
                isHovering = hovering
            }
        }
    }
}

// MARK: - Preview

#Preview {
    ExistingHostsView(isPresented: .constant(true))
        .environmentObject(HostsGroupViewModel())
}
