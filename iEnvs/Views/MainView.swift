import SwiftUI

struct MainView: View {
    @EnvironmentObject var viewModel: EnvGroupViewModel
    @State private var columnVisibility: NavigationSplitViewVisibility = .all
    @State private var showExportImport: Bool = false

    var body: some View {
        NavigationSplitView(columnVisibility: $columnVisibility) {
            // Left Sidebar
            SidebarView(selectedGroupID: $viewModel.selectedGroupId)
                .navigationSplitViewColumnWidth(min: 200, ideal: 250, max: 350)
        } detail: {
            // Right Detail
            if let groupID = viewModel.selectedGroupId,
               let group = viewModel.groups.first(where: { $0.id == groupID }) {
                DetailView(group: group)
            } else {
                EmptyStateView()
            }
        }
        .searchable(text: $viewModel.searchText, prompt: "搜索分组或变量")
        .toolbar {
            ToolbarItemGroup(placement: .automatic) {
                Button(action: { showExportImport = true }) {
                    Label("导入/导出", systemImage: "square.and.arrow.up.on.square")
                }
            }
        }
        .sheet(isPresented: $showExportImport) {
            ExportImportView(isPresented: $showExportImport)
                .environmentObject(viewModel)
        }
        .onAppear {
            viewModel.loadData()
        }
        .overlay(alignment: .bottom) {
            if viewModel.showNotification {
                notificationBanner
            }
        }
    }

    private var notificationBanner: some View {
        Text(viewModel.notificationMessage)
            .font(.callout)
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(.ultraThinMaterial)
            .cornerRadius(8)
            .shadow(radius: 4)
            .padding(.bottom, 16)
            .transition(.move(edge: .bottom).combined(with: .opacity))
            .onAppear {
                DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
                    withAnimation {
                        viewModel.showNotification = false
                    }
                }
            }
    }
}

#Preview {
    MainView()
        .environmentObject(EnvGroupViewModel())
}
