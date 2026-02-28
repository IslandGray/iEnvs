import SwiftUI

struct AddHostsGroupSheet: View {
    @EnvironmentObject var viewModel: HostsGroupViewModel
    @Environment(\.dismiss) private var dismiss

    @State private var groupName = ""
    @State private var groupDescription = ""
    @State private var validationError: String?

    var isValid: Bool {
        !groupName.trimmingCharacters(in: .whitespaces).isEmpty
    }

    var body: some View {
        VStack(spacing: 20) {
            // Header
            Text(L10n.Hosts.addGroupTitle)
                .font(.title2)
                .bold()

            // Form
            VStack(alignment: .leading, spacing: 16) {
                VStack(alignment: .leading, spacing: 8) {
                    Text(L10n.AddGroup.groupName)
                        .font(.headline)

                    TextField(L10n.Hosts.groupNamePlaceholder, text: $groupName)
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

                    TextField(L10n.Hosts.descriptionPlaceholder, text: $groupDescription)
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

                Button(L10n.General.confirm) {
                    addGroup()
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

        if trimmedName.count > 100 {
            validationError = L10n.AddGroup.nameTooLong
            return
        }

        if viewModel.hostsGroups.contains(where: { $0.name == trimmedName }) {
            validationError = L10n.AddGroup.nameExists
            return
        }

        validationError = nil
    }

    private func addGroup() {
        let trimmedName = groupName.trimmingCharacters(in: .whitespaces)
        let trimmedDescription = groupDescription.trimmingCharacters(in: .whitespaces)

        viewModel.addHostsGroup(name: trimmedName, description: trimmedDescription)
        dismiss()
    }
}
