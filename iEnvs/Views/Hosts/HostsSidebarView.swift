import SwiftUI

struct HostsSidebarView: View {
    @EnvironmentObject var viewModel: HostsGroupViewModel
    @Binding var selectedGroupID: UUID?
    @State private var showAddGroupSheet = false
    @State private var showDeleteConfirmation = false

    var filteredGroups: [HostGroup] {
        if viewModel.hostsSearchText.isEmpty {
            return viewModel.hostsGroups
        } else {
            return viewModel.hostsGroups.filter { group in
                group.name.localizedCaseInsensitiveContains(viewModel.hostsSearchText)
                || group.description.localizedCaseInsensitiveContains(viewModel.hostsSearchText)
                || group.entries.contains { entry in
                    entry.ip.localizedCaseInsensitiveContains(viewModel.hostsSearchText)
                    || entry.hostname.localizedCaseInsensitiveContains(viewModel.hostsSearchText)
                }
            }
        }
    }

    var body: some View {
        List(selection: $selectedGroupID) {
            ForEach(filteredGroups) { group in
                HostsGroupRowView(group: group)
                    .tag(group.id)
                    .contextMenu {
                        Button(L10n.General.rename) {
                            // TODO: Implement rename
                        }

                        Button(L10n.General.duplicate) {
                            viewModel.duplicateHostsGroup(id: group.id)
                        }

                        Divider()

                        Button(L10n.General.delete, role: .destructive) {
                            selectedGroupID = group.id
                            showDeleteConfirmation = true
                        }
                    }
            }
            .onMove { source, destination in
                viewModel.moveHostsGroup(from: source, to: destination)
            }
            .onDelete { indexSet in
                for index in indexSet {
                    viewModel.deleteHostsGroup(id: filteredGroups[index].id)
                }
            }
        }
        .navigationTitle(L10n.Hosts.groups)
        .toolbar {
            ToolbarItemGroup(placement: .primaryAction) {
                Button(action: { showAddGroupSheet = true }) {
                    Label(L10n.Hosts.addGroup, systemImage: "plus")
                }

                Button(action: {
                    if selectedGroupID != nil {
                        showDeleteConfirmation = true
                    }
                }) {
                    Label(L10n.Hosts.deleteGroup, systemImage: "minus")
                }
                .disabled(selectedGroupID == nil)
            }
        }
        .sheet(isPresented: $showAddGroupSheet) {
            AddHostsGroupSheet()
        }
        .alert(L10n.Sidebar.confirmDelete, isPresented: $showDeleteConfirmation) {
            Button(L10n.General.cancel, role: .cancel) { }
            Button(L10n.General.delete, role: .destructive) {
                if let groupID = selectedGroupID {
                    viewModel.deleteHostsGroup(id: groupID)
                    selectedGroupID = nil
                }
            }
        } message: {
            if let groupID = selectedGroupID,
               let group = viewModel.hostsGroups.first(where: { $0.id == groupID }) {
                Text(L10n.Sidebar.confirmDeleteMessage(group.name))
            }
        }
    }
}
