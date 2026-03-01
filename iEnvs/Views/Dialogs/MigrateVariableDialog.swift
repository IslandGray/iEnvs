import SwiftUI

struct MigrateVariableDialog: View {
    @Binding var isPresented: Bool
    let variable: ParsedExportVariable
    @Binding var newValue: String
    let groups: [EnvGroup]
    let onMigrate: (UUID?, String?) -> Void

    @State private var selectedGroupId: UUID? = nil
    @State private var createNewGroup = false
    @State private var newGroupName: String = ""

    var body: some View {
        VStack(spacing: 20) {
            // Header
            HStack {
                Image(systemName: "arrow.right.circle.fill")
                    .font(.title2)
                    .foregroundStyle(.blue)

                Text(L10n.Migrate.title)
                    .font(.title3)
                    .fontWeight(.semibold)

                Spacer()
            }

            // Warning message
            HStack(alignment: .top, spacing: 8) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundStyle(.orange)

                Text(L10n.Migrate.warningMessage)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(12)
            .background(Color.orange.opacity(0.1))
            .cornerRadius(8)

            // Variable info
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text(L10n.Migrate.keyLabel)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    Spacer()
                    Text(variable.key)
                        .font(.system(.body, design: .monospaced))
                }

                Divider()

                HStack {
                    Text(L10n.Migrate.currentValueLabel)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    Spacer()
                    Text(variable.value)
                        .font(.system(.body, design: .monospaced))
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                        .truncationMode(.middle)
                }

                // New value editor
                VStack(alignment: .leading, spacing: 6) {
                    Text(L10n.Migrate.newValueLabel)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)

                    TextEditor(text: $newValue)
                        .font(.system(.body, design: .monospaced))
                        .frame(height: 60)
                        .border(Color.secondary.opacity(0.2), width: 1)
                        .cornerRadius(4)
                }
            }
            .padding(12)
            .background(Color(nsColor: .controlBackgroundColor))
            .cornerRadius(8)

            // Group selection
            VStack(alignment: .leading, spacing: 12) {
                Text(L10n.Migrate.targetGroupLabel)
                    .font(.subheadline)
                    .fontWeight(.medium)

                if groups.isEmpty {
                    // No existing groups, force create new
                    Toggle(isOn: .constant(true)) {
                        Text(L10n.Migrate.createNewGroup)
                    }
                    .toggleStyle(.checkbox)
                    .disabled(true)

                    TextField(L10n.Migrate.newGroupNamePlaceholder, text: $newGroupName)
                        .textFieldStyle(.roundedBorder)
                } else {
                    Toggle(isOn: $createNewGroup) {
                        Text(L10n.Migrate.createNewGroup)
                    }
                    .toggleStyle(.checkbox)

                    if createNewGroup {
                        TextField(L10n.Migrate.newGroupNamePlaceholder, text: $newGroupName)
                            .textFieldStyle(.roundedBorder)
                    } else {
                        Picker(L10n.Migrate.selectGroup, selection: $selectedGroupId) {
                            Text(L10n.Migrate.selectGroupPrompt).tag(nil as UUID?)
                            ForEach(groups) { group in
                                Text(group.name).tag(group.id as UUID?)
                            }
                        }
                        .pickerStyle(.menu)
                        .labelsHidden()
                    }
                }
            }

            Spacer()

            // Buttons
            HStack {
                Button(L10n.General.cancel) {
                    isPresented = false
                }
                .keyboardShortcut(.cancelAction)

                Spacer()

                Button(L10n.Migrate.confirmButton) {
                    let targetId = createNewGroup ? nil : selectedGroupId
                    let newName = createNewGroup ? (newGroupName.isEmpty ? nil : newGroupName) : nil
                    onMigrate(targetId, newName)
                    isPresented = false
                }
                .keyboardShortcut(.defaultAction)
                .disabled(!canMigrate)
            }
        }
        .padding()
        .frame(width: 450, height: 500)
    }

    private var canMigrate: Bool {
        if groups.isEmpty || createNewGroup {
            return !newGroupName.isEmpty
        } else {
            return selectedGroupId != nil
        }
    }
}

// MARK: - Preview

#Preview {
    MigrateVariableDialog(
        isPresented: .constant(true),
        variable: ParsedExportVariable(
            key: "TEST_VAR",
            value: "test_value",
            rawLine: "export TEST_VAR=test_value",
            lineNumber: 10,
            isInManagedSection: false
        ),
        newValue: .constant("test_value"),
        groups: [],
        onMigrate: { _, _ in }
    )
}
