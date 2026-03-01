import SwiftUI

enum ManageTab: String, CaseIterable {
    case envVars = "envVars"
    case hosts = "hosts"

    var label: String {
        switch self {
        case .envVars: return L10n.Hosts.tabEnvVars
        case .hosts: return L10n.Hosts.tabHosts
        }
    }

    var icon: String {
        switch self {
        case .envVars: return "terminal"
        case .hosts: return "network"
        }
    }
}

struct MainView: View {
    @EnvironmentObject var viewModel: EnvGroupViewModel
    @EnvironmentObject var hostsViewModel: HostsGroupViewModel
    @ObservedObject var localization = LocalizationManager.shared
    @State private var columnVisibility: NavigationSplitViewVisibility = .all
    @State private var showExportImport: Bool = false
    @State private var showHostsExportImport: Bool = false
    @State private var showExistingVariables: Bool = false
    @State private var showExistingHosts: Bool = false
    @State private var selectedTab: ManageTab = .envVars

    var body: some View {
        NavigationSplitView(columnVisibility: $columnVisibility) {
            VStack(spacing: 0) {
                // Tab switcher at top of sidebar
                Picker("", selection: $selectedTab) {
                    ForEach(ManageTab.allCases, id: \.self) { tab in
                        Label(tab.label, systemImage: tab.icon).tag(tab)
                    }
                }
                .pickerStyle(.segmented)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)

                Divider()

                // Sidebar content based on selected tab
                switch selectedTab {
                case .envVars:
                    SidebarView(selectedGroupID: $viewModel.selectedGroupId)
                case .hosts:
                    HostsSidebarView(selectedGroupID: $hostsViewModel.selectedHostsGroupId)
                }
            }
            .navigationSplitViewColumnWidth(min: 200, ideal: 250, max: 350)
        } detail: {
            switch selectedTab {
            case .envVars:
                if let groupID = viewModel.selectedGroupId,
                   let group = viewModel.groups.first(where: { $0.id == groupID }) {
                    DetailView(group: group)
                } else {
                    EmptyStateView()
                }
            case .hosts:
                if let groupID = hostsViewModel.selectedHostsGroupId,
                   let group = hostsViewModel.hostsGroups.first(where: { $0.id == groupID }) {
                    HostsDetailView(group: group)
                } else {
                    HostsEmptyStateView()
                }
            }
        }
        .searchable(
            text: selectedTab == .envVars ? $viewModel.searchText : $hostsViewModel.hostsSearchText,
            prompt: L10n.MainView.searchPrompt
        )
        .toolbar {
            ToolbarItemGroup(placement: .automatic) {
                // 导入现有配置按钮
                Button(action: {
                    if selectedTab == .envVars {
                        showExistingVariables = true
                    } else {
                        showExistingHosts = true
                    }
                }) {
                    let count = selectedTab == .envVars
                        ? viewModel.existingVariables.count
                        : hostsViewModel.existingHosts.count
                    Label(
                        L10n.MainView.existingConfig(count),
                        systemImage: count > 0 ? "exclamationmark.triangle" : "doc.text.magnifyingglass"
                    )
                }
                .disabled(selectedTab == .envVars ? false : !hostsViewModel.hostsFileManager.isHostsFileReadable())

                Button(action: {
                    if selectedTab == .envVars {
                        showExportImport = true
                    } else {
                        showHostsExportImport = true
                    }
                }) {
                    Label(L10n.MainView.exportImport, systemImage: "square.and.arrow.up.on.square")
                }
            }
        }
        .sheet(isPresented: $showExportImport) {
            ExportImportView(isPresented: $showExportImport)
                .environmentObject(viewModel)
        }
        .sheet(isPresented: $showHostsExportImport) {
            HostsExportImportView(isPresented: $showHostsExportImport)
                .environmentObject(hostsViewModel)
        }
        .sheet(isPresented: $showExistingVariables) {
            ExistingEnvVariablesView(isPresented: $showExistingVariables)
                .environmentObject(viewModel)
        }
        .sheet(isPresented: $showExistingHosts) {
            ExistingHostsView(isPresented: $showExistingHosts)
                .environmentObject(hostsViewModel)
        }
        .onAppear {
            viewModel.loadData()
            hostsViewModel.loadData()
        }
        .overlay(alignment: .bottom) {
            if viewModel.showNotification {
                notificationBanner(message: viewModel.notificationMessage) {
                    viewModel.showNotification = false
                }
            }
            if hostsViewModel.showNotification {
                notificationBanner(message: hostsViewModel.notificationMessage) {
                    hostsViewModel.showNotification = false
                }
            }
        }
    }

    private func notificationBanner(message: String, dismiss: @escaping () -> Void) -> some View {
        Text(message)
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
                        dismiss()
                    }
                }
            }
    }
}

#Preview {
    MainView()
        .environmentObject(EnvGroupViewModel())
        .environmentObject(HostsGroupViewModel())
}
