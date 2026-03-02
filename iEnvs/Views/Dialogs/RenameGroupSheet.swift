import SwiftUI

struct RenameGroupSheet: View {
    @EnvironmentObject var viewModel: EnvGroupViewModel
    @Environment(\.dismiss) private var dismiss

    let group: EnvGroup

    @State private var groupName = ""
    @State private var groupDescription = ""
    @State private var validationError: String?

    var isValid: Bool {
        !groupName.trimmingCharacters(in: .whitespaces).isEmpty &&
        (groupName.trimmingCharacters(in: .whitespaces) != group.name ||
         groupDescription.trimmingCharacters(in: .whitespaces) != group.description)
    }

    init(group: EnvGroup) {
        self.group = group
        _groupName = State(initialValue: group.name)
        _groupDescription = State(initialValue: group.description)
    }

    var body: some View {
        VStack(spacing: 20) {
            // Header
            Text(L10n.General.rename)
                .font(.title2)
                .bold()

            // Form
            VStack(alignment: .leading, spacing: 16) {
                VStack(alignment: .leading, spacing: 8) {
                    Text(L10n.AddGroup.groupName)
                        .font(.headline)

                    TextField(L10n.AddGroup.groupNamePlaceholder, text: $groupName)
                        .textFieldStyle(.roundedBorder)
                        .onChange(of: groupName) { _ in
                            validateName()
                        }

                    if let error = validationError {
                        Text(error)
                            .font(.caption)
                            .foregroundStyle(.red)
                    }
                }

                VStack(alignment: .leading, spacing: 8) {
                    Text(L10n.AddGroup.descriptionLabel)
                        .font(.headline)

                    TextField(L10n.AddGroup.descriptionPlaceholder, text: $groupDescription)
                        .textFieldStyle(.roundedBorder)
                }
            }
            .padding()
            .background(Color(.controlBackgroundColor))
            .cornerRadius(8)

            // Buttons
            HStack {
                Button(L10n.General.cancel) {
                    dismiss()
                }
                .keyboardShortcut(.cancelAction)

                Spacer()

                Button(L10n.General.save) {
                    saveChanges()
                }
                .keyboardShortcut(.defaultAction)
                .disabled(!isValid)
            }
        }
        .padding(24)
        .frame(width: 450)
    }

    private func validateName() {
        let trimmedName = groupName.trimmingCharacters(in: .whitespaces)

        if trimmedName.isEmpty {
            validationError = nil
            return
        }

        // Check if name is too long
        if trimmedName.count > 100 {
            validationError = L10n.AddGroup.nameTooLong
            return
        }

        // Check if name already exists (but allow keeping the same name)
        if trimmedName != group.name &&
           viewModel.groups.contains(where: { $0.name == trimmedName }) {
            validationError = L10n.AddGroup.nameExists
            return
        }

        validationError = nil
    }

    private func saveChanges() {
        let trimmedName = groupName.trimmingCharacters(in: .whitespaces)
        let trimmedDescription = groupDescription.trimmingCharacters(in: .whitespaces)

        viewModel.updateGroup(id: group.id, name: trimmedName, description: trimmedDescription)
        dismiss()
    }
}

#Preview {
    RenameGroupSheet(group: EnvGroup(name: "测试分组", description: "测试描述"))
        .environmentObject(EnvGroupViewModel())
}
