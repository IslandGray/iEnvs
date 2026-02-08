//
//  SettingsView.swift
//  iEnvs
//
//  Created on 2026-02-08.
//

import SwiftUI

struct SettingsView: View {
    @StateObject private var settingsVM = SettingsViewModel()

    var body: some View {
        TabView {
            GeneralSettingsView(viewModel: settingsVM)
                .tabItem {
                    Label("通用", systemImage: "gearshape")
                }
                .tag(0)

            ShellSettingsView(viewModel: settingsVM)
                .tabItem {
                    Label("Shell", systemImage: "terminal")
                }
                .tag(1)

            BackupSettingsView(viewModel: settingsVM)
                .tabItem {
                    Label("备份", systemImage: "clock.arrow.circlepath")
                }
                .tag(2)
        }
        .frame(width: 600, height: 400)
        .onChange(of: settingsVM.settings) { _ in
            settingsVM.saveSettings()
        }
    }
}

// MARK: - Preview

#Preview {
    SettingsView()
}
