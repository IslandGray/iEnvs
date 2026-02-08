//
//  DetailView.swift
//  iEnvs
//
//  Created on 2026-02-08.
//

import SwiftUI

struct DetailView: View {
    let group: EnvGroup
    @EnvironmentObject var viewModel: EnvGroupViewModel
    @State private var filterText: String = ""
    @State private var showAddVariable: Bool = false
    @State private var selectedVariableIDs = Set<UUID>()

    var filteredVariables: [EnvVariable] {
        if filterText.isEmpty {
            return group.variables
        } else {
            return group.variables.filter { variable in
                variable.key.localizedCaseInsensitiveContains(filterText) ||
                variable.value.localizedCaseInsensitiveContains(filterText)
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

            // Variable list
            if filteredVariables.isEmpty {
                EmptyStateView()
            } else {
                variableList
            }
        }
        .sheet(isPresented: $showAddVariable) {
            AddVariableSheet(
                group: group,
                isPresented: $showAddVariable
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
            // Add variable button
            Button(action: { showAddVariable = true }) {
                Label("添加变量", systemImage: "plus")
            }
            .buttonStyle(.bordered)
            .help("添加新的环境变量")

            // Delete selected button
            Button(action: deleteSelectedVariables) {
                Label("删除", systemImage: "trash")
            }
            .buttonStyle(.bordered)
            .disabled(selectedVariableIDs.isEmpty)
            .help("删除选中的变量")

            Spacer()

            // Filter search box
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(.secondary)

                TextField("过滤变量...", text: $filterText)
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

    // MARK: - Variable List

    private var variableList: some View {
        Table(of: EnvVariable.self, selection: $selectedVariableIDs) {
            TableColumn("变量名") { variable in
                Text(variable.key)
                    .font(.system(.body, design: .monospaced))
                    .foregroundColor(.primary)
            }
            .width(min: 150, ideal: 250, max: 400)

            TableColumn("变量值") { variable in
                VariableValueView(variable: variable)
            }
            .width(min: 200)
        } rows: {
            ForEach(filteredVariables) { variable in
                TableRow(variable)
                    .contextMenu {
                        variableContextMenu(for: variable)
                    }
            }
        }
    }

    // MARK: - Context Menu

    @ViewBuilder
    private func variableContextMenu(for variable: EnvVariable) -> some View {
        Button("编辑") {
            // TODO: Show edit sheet
        }

        Button("复制值") {
            NSPasteboard.general.clearContents()
            NSPasteboard.general.setString(variable.value, forType: .string)
        }

        Divider()

        Button(variable.isSensitive ? "标记为普通" : "标记为敏感") {
            viewModel.toggleSensitive(in: group.id, variableId: variable.id)
        }

        Divider()

        Button("删除", role: .destructive) {
            viewModel.deleteVariable(from: group.id, variableId: variable.id)
        }
    }

    // MARK: - Actions

    private func deleteSelectedVariables() {
        for variableID in selectedVariableIDs {
            viewModel.deleteVariable(from: group.id, variableId: variableID)
        }
        selectedVariableIDs.removeAll()
    }
}

// MARK: - Variable Value View

struct VariableValueView: View {
    let variable: EnvVariable
    @State private var showValue = false

    var body: some View {
        HStack {
            if variable.isSensitive && !showValue {
                Text("••••••••")
                    .font(.system(.body, design: .monospaced))
                    .foregroundStyle(.secondary)

                Button(action: { showValue.toggle() }) {
                    Image(systemName: "eye")
                        .font(.caption)
                }
                .buttonStyle(.plain)
                .help("显示敏感值")
            } else {
                Text(variable.value)
                    .font(.system(.body, design: .monospaced))
                    .textSelection(.enabled)

                if variable.isSensitive {
                    Button(action: { showValue.toggle() }) {
                        Image(systemName: "eye.slash")
                            .font(.caption)
                    }
                    .buttonStyle(.plain)
                    .help("隐藏敏感值")
                }
            }
        }
    }
}

// MARK: - Preview

#Preview {
    DetailView(
        group: EnvGroup(
            name: "示例分组",
            description: "这是一个示例分组",
            variables: [
                EnvVariable(key: "NODE_ENV", value: "development"),
                EnvVariable(key: "API_KEY", value: "sk-1234567890", isSensitive: true)
            ]
        )
    )
    .environmentObject(EnvGroupViewModel())
    .frame(width: 600, height: 400)
}
