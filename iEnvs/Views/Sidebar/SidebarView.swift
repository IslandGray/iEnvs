import SwiftUI

struct SidebarView: View {
    @EnvironmentObject var viewModel: EnvGroupViewModel
    @Binding var selectedGroupID: UUID?
    @State private var showAddGroupSheet = false
    @State private var showDeleteConfirmation = false

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
                        Button("重命名") {
                            // TODO: Implement rename
                        }

                        Button("复制") {
                            viewModel.duplicateGroup(id: group.id)
                        }

                        Divider()

                        Button("删除", role: .destructive) {
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
        .navigationTitle("分组")
        .toolbar {
            ToolbarItemGroup(placement: .primaryAction) {
                Button(action: { showAddGroupSheet = true }) {
                    Label("添加分组", systemImage: "plus")
                }

                Button(action: {
                    if let groupID = selectedGroupID {
                        showDeleteConfirmation = true
                    }
                }) {
                    Label("删除分组", systemImage: "minus")
                }
                .disabled(selectedGroupID == nil)
            }
        }
        .sheet(isPresented: $showAddGroupSheet) {
            AddGroupSheet()
        }
        .alert("确认删除", isPresented: $showDeleteConfirmation) {
            Button("取消", role: .cancel) { }
            Button("删除", role: .destructive) {
                if let groupID = selectedGroupID {
                    viewModel.deleteGroup(id: groupID)
                    selectedGroupID = nil
                }
            }
        } message: {
            if let groupID = selectedGroupID,
               let group = viewModel.groups.first(where: { $0.id == groupID }) {
                Text("确定要删除分组「\(group.name)」吗？此操作不可撤销。")
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
