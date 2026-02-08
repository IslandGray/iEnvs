//
//  VariableRowView.swift
//  iEnvs
//
//  Created on 2026-02-08.
//

import SwiftUI

struct VariableRowView: View {
    let variable: EnvVariable
    let groupId: UUID
    let conflicts: [ConflictInfo]

    @EnvironmentObject var viewModel: EnvGroupViewModel
    @State private var isEditing: Bool = false
    @State private var editKey: String
    @State private var editValue: String
    @State private var showSensitiveValue: Bool = false

    init(variable: EnvVariable, groupId: UUID, conflicts: [ConflictInfo]) {
        self.variable = variable
        self.groupId = groupId
        self.conflicts = conflicts
        self._editKey = State(initialValue: variable.key)
        self._editValue = State(initialValue: variable.value)
    }

    private var hasConflict: Bool {
        conflicts.contains { conflict in
            conflict.key == variable.key && conflict.affectedGroupIDs.contains(groupId)
        }
    }

    var body: some View {
        HStack(spacing: 12) {
            if isEditing {
                editingView
            } else {
                displayView
            }
        }
        .padding(.vertical, 6)
        .padding(.horizontal, 8)
        .background(hasConflict ? Color.yellow.opacity(0.15) : Color.clear)
        .cornerRadius(6)
        .onTapGesture(count: 2) {
            startEditing()
        }
    }

    // MARK: - Display Mode

    private var displayView: some View {
        HStack(spacing: 12) {
            // Conflict indicator
            if hasConflict {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundStyle(.yellow)
                    .font(.caption)
                    .help(conflictTooltip)
            }

            // Variable name
            Text(variable.key)
                .font(.system(.body, design: .monospaced))
                .fontWeight(.medium)
                .frame(maxWidth: .infinity, alignment: .leading)

            // Variable value
            Group {
                if variable.isSensitive && !showSensitiveValue {
                    HStack {
                        Text("••••••••")
                            .foregroundStyle(.secondary)

                        Button(action: { showSensitiveValue = true }) {
                            Image(systemName: "eye")
                        }
                        .buttonStyle(.plain)
                        .help("显示敏感值")
                    }
                } else {
                    HStack {
                        Text(variable.value)
                            .lineLimit(1)
                            .truncationMode(.tail)

                        if variable.isSensitive {
                            Button(action: { showSensitiveValue = false }) {
                                Image(systemName: "eye.slash")
                            }
                            .buttonStyle(.plain)
                            .help("隐藏敏感值")
                        }
                    }
                }
            }
            .font(.system(.body, design: .monospaced))
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .contextMenu {
            contextMenuItems
        }
    }

    // MARK: - Editing Mode

    private var editingView: some View {
        HStack(spacing: 8) {
            // Key input
            TextField("变量名", text: $editKey)
                .textFieldStyle(.roundedBorder)
                .font(.system(.body, design: .monospaced))
                .frame(maxWidth: .infinity)

            // Value input
            TextField("变量值", text: $editValue)
                .textFieldStyle(.roundedBorder)
                .font(.system(.body, design: .monospaced))
                .frame(maxWidth: .infinity)
                .onSubmit {
                    saveEdit()
                }

            // Confirm button
            Button(action: saveEdit) {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(.green)
            }
            .buttonStyle(.plain)
            .help("保存 (Enter)")

            // Cancel button
            Button(action: cancelEdit) {
                Image(systemName: "xmark.circle.fill")
                    .foregroundStyle(.red)
            }
            .buttonStyle(.plain)
            .help("取消 (Esc)")
        }
        .onAppear {
            // Focus on key field when editing starts
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                // Request focus (requires macOS 13+)
            }
        }
    }

    // MARK: - Context Menu

    @ViewBuilder
    private var contextMenuItems: some View {
        Button("编辑") {
            startEditing()
        }

        Button("复制值") {
            NSPasteboard.general.clearContents()
            NSPasteboard.general.setString(variable.value, forType: .string)
        }

        Divider()

        Button(variable.isSensitive ? "取消敏感标记" : "标记为敏感") {
            viewModel.toggleSensitive(in: groupId, variableId: variable.id)
        }

        Divider()

        Button("删除", role: .destructive) {
            viewModel.deleteVariable(from: groupId, variableId: variable.id)
        }
    }

    // MARK: - Actions

    private func startEditing() {
        editKey = variable.key
        editValue = variable.value
        isEditing = true
    }

    private func saveEdit() {
        guard !editKey.isEmpty else { return }

        // Validate key format
        guard Validators.validateEnvKey(editKey) else {
            // Show error
            return
        }

        // Check for duplicate key in group (excluding current variable)
        if let group = viewModel.groups.first(where: { $0.id == groupId }) {
            let isDuplicate = group.variables.contains { existingVar in
                existingVar.key == editKey && existingVar.id != variable.id
            }

            if isDuplicate {
                // Show error: key already exists
                return
            }
        }

        viewModel.updateVariable(
            in: groupId,
            variableId: variable.id,
            key: editKey,
            value: editValue
        )

        isEditing = false
    }

    private func cancelEdit() {
        editKey = variable.key
        editValue = variable.value
        isEditing = false
    }

    private var conflictTooltip: String {
        if let conflict = conflicts.first(where: { $0.key == variable.key }) {
            let groupNames = conflict.affectedGroups.map { $0.name }.joined(separator: ", ")
            return "此变量在以下分组中冲突: \(groupNames)\n最终生效: \(conflict.effectiveGroup.name)"
        }
        return "存在冲突"
    }
}

// MARK: - Preview

#Preview {
    VStack(spacing: 8) {
        VariableRowView(
            variable: EnvVariable(key: "NODE_ENV", value: "development"),
            groupId: UUID(),
            conflicts: []
        )

        VariableRowView(
            variable: EnvVariable(key: "API_KEY", value: "sk-1234567890", isSensitive: true),
            groupId: UUID(),
            conflicts: []
        )

        VariableRowView(
            variable: EnvVariable(key: "CONFLICT_VAR", value: "value1"),
            groupId: UUID(),
            conflicts: [
                ConflictInfo(
                    key: "CONFLICT_VAR",
                    affectedGroups: [
                        EnvGroup(name: "Group A", variables: []),
                        EnvGroup(name: "Group B", variables: [])
                    ],
                    effectiveGroup: EnvGroup(name: "Group B", variables: []),
                    effectiveValue: "value1"
                )
            ]
        )
    }
    .environmentObject(EnvGroupViewModel())
    .padding()
}
