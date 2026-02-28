import SwiftUI

struct HostsDetailView: View {
    let group: HostGroup
    @EnvironmentObject var viewModel: HostsGroupViewModel
    @State private var filterText: String = ""
    @State private var showAddEntry: Bool = false
    @State private var selectedEntryIDs = Set<UUID>()

    var filteredEntries: [HostEntry] {
        if filterText.isEmpty {
            return group.entries
        } else {
            return group.entries.filter { entry in
                entry.ip.localizedCaseInsensitiveContains(filterText) ||
                entry.hostname.localizedCaseInsensitiveContains(filterText) ||
                entry.comment.localizedCaseInsensitiveContains(filterText)
            }
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            // Header section
            headerSection

            Divider()

            // Toolbar section
            toolbarSection

            Divider()

            // Entry list
            if filteredEntries.isEmpty {
                HostsEmptyStateView()
            } else {
                entryList
            }
        }
        .sheet(isPresented: $showAddEntry) {
            AddHostEntrySheet(
                group: group,
                isPresented: $showAddEntry
            )
            .environmentObject(viewModel)
        }
    }

    // MARK: - Header Section

    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(group.name)
                .font(.title2)
                .fontWeight(.bold)

            if !group.description.isEmpty {
                Text(group.description)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
    }

    // MARK: - Toolbar Section

    private var toolbarSection: some View {
        HStack(spacing: 12) {
            Button(action: { showAddEntry = true }) {
                Label(L10n.Hosts.addEntry, systemImage: "plus")
            }
            .buttonStyle(.bordered)
            .help(L10n.Hosts.addEntryHelp)

            Button(action: deleteSelectedEntries) {
                Label(L10n.General.delete, systemImage: "trash")
            }
            .buttonStyle(.bordered)
            .disabled(selectedEntryIDs.isEmpty)
            .help(L10n.Hosts.deleteEntryHelp)

            Spacer()

            // Filter search box
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(.secondary)

                TextField(L10n.Hosts.filterPlaceholder, text: $filterText)
                    .textFieldStyle(.plain)
                    .frame(width: 200)

                if !filterText.isEmpty {
                    Button(action: { filterText = "" }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(.secondary)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(Color(nsColor: .controlBackgroundColor))
            .cornerRadius(6)
        }
        .padding()
    }

    // MARK: - Entry List

    private var entryList: some View {
        Table(of: HostEntry.self, selection: $selectedEntryIDs) {
            TableColumn(L10n.Hosts.columnEnabled) { entry in
                Toggle("", isOn: Binding(
                    get: { entry.isEnabled },
                    set: { _ in
                        viewModel.toggleHostEntry(in: group.id, entryId: entry.id)
                    }
                ))
                .toggleStyle(.checkbox)
                .labelsHidden()
            }
            .width(50)

            TableColumn(L10n.Hosts.columnIP) { entry in
                Text(entry.ip)
                    .font(.system(.body, design: .monospaced))
                    .foregroundColor(entry.isEnabled ? .primary : .secondary)
            }
            .width(min: 120, ideal: 160, max: 250)

            TableColumn(L10n.Hosts.columnHostname) { entry in
                Text(entry.hostname)
                    .font(.system(.body, design: .monospaced))
                    .foregroundColor(entry.isEnabled ? .primary : .secondary)
            }
            .width(min: 150, ideal: 250, max: 400)

            TableColumn(L10n.Hosts.columnComment) { entry in
                Text(entry.comment)
                    .font(.body)
                    .foregroundStyle(.secondary)
            }
            .width(min: 100)
        } rows: {
            ForEach(filteredEntries) { entry in
                TableRow(entry)
                    .contextMenu {
                        entryContextMenu(for: entry)
                    }
            }
        }
    }

    // MARK: - Context Menu

    @ViewBuilder
    private func entryContextMenu(for entry: HostEntry) -> some View {
        Button(L10n.Detail.copyValue) {
            NSPasteboard.general.clearContents()
            NSPasteboard.general.setString(entry.hostsLine, forType: .string)
        }

        Divider()

        Button(L10n.General.delete, role: .destructive) {
            viewModel.deleteHostEntry(from: group.id, entryId: entry.id)
        }
    }

    // MARK: - Actions

    private func deleteSelectedEntries() {
        for entryID in selectedEntryIDs {
            viewModel.deleteHostEntry(from: group.id, entryId: entryID)
        }
        selectedEntryIDs.removeAll()
    }
}
