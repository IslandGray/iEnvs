import SwiftUI

struct ExistingEnvVariablesView: View {
    @EnvironmentObject var viewModel: EnvGroupViewModel
    @Binding var isPresented: Bool

    @State private var showingMigrateDialog = false
    @State private var showingDeleteConfirmation = false
    @State private var selectedVariable: ParsedExportVariable?
    @State private var editNewValue: String = ""

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(L10n.Existing.title)
                        .font(.title2)
                        .fontWeight(.bold)

                    Text(L10n.Existing.subtitle(viewModel.existingVariables.count))
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                Button(action: { isPresented = false }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(.secondary)
                        .font(.title3)
                }
                .buttonStyle(.plain)
            }
            .padding()

            Divider()

            // Content
            if viewModel.existingVariables.isEmpty {
                emptyStateView
            } else {
                listView
            }

            Divider()

            // Footer
            HStack {
                Spacer()

                Button(L10n.General.close) {
                    isPresented = false
                }
                .keyboardShortcut(.cancelAction)
            }
            .padding()
        }
        .frame(width: 600, height: 500)
        .onAppear {
            viewModel.loadExistingVariables()
        }
        .sheet(isPresented: $showingMigrateDialog) {
            if let variable = selectedVariable {
                MigrateVariableDialog(
                    isPresented: $showingMigrateDialog,
                    variable: variable,
                    newValue: $editNewValue,
                    groups: viewModel.groups,
                    onMigrate: { targetGroupId, newGroupName in
                        viewModel.migrateExistingVariable(
                            variable,
                            newValue: editNewValue.isEmpty ? nil : editNewValue,
                            targetGroupId: targetGroupId,
                            newGroupName: newGroupName
                        )
                    }
                )
            }
        }
        .alert(L10n.Existing.deleteConfirmTitle, isPresented: $showingDeleteConfirmation) {
            Button(L10n.General.cancel, role: .cancel) {}
            Button(L10n.General.delete, role: .destructive) {
                if let variable = selectedVariable {
                    viewModel.deleteExistingVariable(variable)
                }
            }
        } message: {
            if let variable = selectedVariable {
                Text(L10n.Existing.deleteConfirmMessage(variable.key))
            }
        }
    }

    // MARK: - Empty State

    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Image(systemName: "checkmark.circle")
                .font(.system(size: 48))
                .foregroundStyle(.secondary)

            Text(L10n.Existing.emptyTitle)
                .font(.title3)
                .fontWeight(.semibold)

            Text(L10n.Existing.emptyMessage)
                .font(.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(nsColor: .controlBackgroundColor))
    }

    // MARK: - List View

    private var listView: some View {
        List(viewModel.existingVariables) { variable in
            ExistingVariableRow(
                variable: variable,
                onEdit: {
                    selectedVariable = variable
                    editNewValue = variable.value
                    showingMigrateDialog = true
                },
                onDelete: {
                    selectedVariable = variable
                    showingDeleteConfirmation = true
                }
            )
        }
        .listStyle(.plain)
    }
}

// MARK: - Existing Variable Row

struct ExistingVariableRow: View {
    let variable: ParsedExportVariable
    let onEdit: () -> Void
    let onDelete: () -> Void

    @State private var isHovering = false

    var body: some View {
        HStack(spacing: 12) {
            // Key
            VStack(alignment: .leading, spacing: 4) {
                Text(variable.key)
                    .font(.system(.body, design: .monospaced))
                    .fontWeight(.medium)

                Text(L10n.Existing.lineNumber(variable.lineNumber))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .frame(width: 150, alignment: .leading)

            // Value
            Text(variable.value)
                .font(.system(.body, design: .monospaced))
                .lineLimit(1)
                .truncationMode(.middle)
                .foregroundStyle(.secondary)

            Spacer()

            // Actions
            HStack(spacing: 8) {
                Button(action: onEdit) {
                    Label(L10n.Existing.editMigrate, systemImage: "arrow.right.circle")
                }
                .buttonStyle(.borderless)
                .foregroundStyle(.blue)

                Button(action: onDelete) {
                    Label(L10n.General.delete, systemImage: "trash")
                }
                .buttonStyle(.borderless)
                .foregroundStyle(.red)
            }
            .opacity(isHovering ? 1 : 0)
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
        .background(isHovering ? Color(nsColor: .selectedControlColor).opacity(0.3) : Color.clear)
        .cornerRadius(6)
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.15)) {
                isHovering = hovering
            }
        }
    }
}

// MARK: - Preview

#Preview {
    ExistingEnvVariablesView(isPresented: .constant(true))
        .environmentObject(EnvGroupViewModel())
}
