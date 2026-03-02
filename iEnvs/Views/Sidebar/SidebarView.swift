import SwiftUI

struct SidebarView: View {
    @EnvironmentObject var viewModel: EnvGroupViewModel
    @Binding var selectedGroupID: UUID?
    @State private var showAddGroupSheet = false
    @State private var showDeleteConfirmation = false
    @State private var showRenameSheet = false
    @State private var groupToRename: EnvGroup?

    var filteredGroups: [EnvGroup] {
        if viewModel.searchText.isEmpty {
            return viewModel.groups
        } else {
            return viewModel.groups.filter { group in
                group.name.localizedCaseInsensitiveContains(viewModel.searchText)
                || group.description.localizedCaseInsensitiveContains(viewModel.searchText)
                || group.variables.contains { variable in
                    variable.key.localizedCaseInsensitiveContains(viewModel.searchText)
                    || variable.value.localizedCaseInsensitiveContains(viewModel.searchText)
                }
            }
        }
    }

    var body: some View {
        List(selection: $selectedGroupID) {
            ForEach(filteredGroups) { group in
                GroupRowView(group: group)
                    .tag(group.id)
                    .contextMenu {
                        Button(L10n.General.rename) {
                            groupToRename = group
                            showRenameSheet = true
                        }

                        Button(L10n.General.duplicate) {
                            viewModel.duplicateGroup(id: group.id)
                        }

                        Divider()

                        Button(L10n.General.delete, role: .destructive) {
                            selectedGroupID = group.id
                            showDeleteConfirmation = true
                        }
                    }
            }
            .onMove { source, destination in
                viewModel.moveGroup(from: source, to: destination)
            }
            .onDelete { indexSet in
                for index in indexSet {
                    viewModel.deleteGroup(id: filteredGroups[index].id)
                }
            }
        }
        .navigationTitle(L10n.Sidebar.groups)
        .toolbar {
            ToolbarItemGroup(placement: .primaryAction) {
                Button(action: { showAddGroupSheet = true }) {
                    Label(L10n.Sidebar.addGroup, systemImage: "plus")
                }

                Button(action: {
                    if let groupID = selectedGroupID {
                        showDeleteConfirmation = true
                    }
                }) {
                    Label(L10n.Sidebar.deleteGroup, systemImage: "minus")
                }
                .disabled(selectedGroupID == nil)
            }
        }
        .sheet(isPresented: $showAddGroupSheet) {
            AddGroupSheet()
        }
        .sheet(isPresented: $showRenameSheet) {
            if let group = groupToRename {
                RenameGroupSheet(group: group)
            }
        }
        .alert(L10n.Sidebar.confirmDelete, isPresented: $showDeleteConfirmation) {
            Button(L10n.General.cancel, role: .cancel) { }
            Button(L10n.General.delete, role: .destructive) {
                if let groupID = selectedGroupID {
                    viewModel.deleteGroup(id: groupID)
                    selectedGroupID = nil
                }
            }
        } message: {
            if let groupID = selectedGroupID,
               let group = viewModel.groups.first(where: { $0.id == groupID }) {
                Text(L10n.Sidebar.confirmDeleteMessage(group.name))
            }
        }
    }
}

#Preview {
    NavigationSplitView {
        SidebarView(selectedGroupID: .constant(nil))
            .environmentObject(EnvGroupViewModel())
    } detail: {
        Text("Detail")
    }
}
