import SwiftUI

struct EditVariableSheet: View {
    let variable: EnvVariable
    let group: EnvGroup
    @Binding var isPresented: Bool
    @EnvironmentObject var viewModel: EnvGroupViewModel

    @State private var key: String = ""
    @State private var value: String = ""
    @State private var isSensitive: Bool = false
    @State private var containsShellRef: Bool = false
    @State private var errorMessage: String?

    private var isKeyValid: Bool {
        Validators.validateEnvKey(key)
    }

    private var keyAlreadyExists: Bool {
        group.variables.contains { $0.key == key && $0.id != variable.id }
    }

    private var canSave: Bool {
        !key.isEmpty && isKeyValid && !keyAlreadyExists && !value.isEmpty
    }

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text(L10n.EditVariable.title)
                    .font(.title2)
                    .fontWeight(.bold)

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
            ScrollView {
                VStack(spacing: 20) {
                    // Key input
                    VStack(alignment: .leading, spacing: 6) {
                        Text(L10n.AddVariable.variableName)
                            .font(.headline)

                        TextField(L10n.AddVariable.variableNamePlaceholder, text: $key)
                            .textFieldStyle(.roundedBorder)
                            .font(.system(.body, design: .monospaced))
                            .onChange(of: key) { _ in
                                errorMessage = nil
                                validateKey()
                            }

                        HStack(spacing: 4) {
                            if !key.isEmpty {
                                if isKeyValid {
                                    if keyAlreadyExists {
                                        Image(systemName: "xmark.circle.fill")
                                            .foregroundStyle(.red)
                                        Text(L10n.AddVariable.nameExists)
                                            .font(.caption)
                                            .foregroundStyle(.red)
                                    } else {
                                        Image(systemName: "checkmark.circle.fill")
                                            .foregroundStyle(.green)
                                        Text(L10n.AddVariable.nameValid)
                                            .font(.caption)
                                            .foregroundStyle(.green)
                                    }
                                } else {
                                    Image(systemName: "xmark.circle.fill")
                                        .foregroundStyle(.red)
                                    Text(L10n.AddVariable.nameInvalid)
                                        .font(.caption)
                                        .foregroundStyle(.red)
                                }
                            }
                        }
                    }

                    // Value input
                    VStack(alignment: .leading, spacing: 6) {
                        Text(L10n.AddVariable.variableValue)
                            .font(.headline)

                        TextField(L10n.AddVariable.variableValuePlaceholder, text: $value)
                            .textFieldStyle(.roundedBorder)
                            .font(.system(.body, design: .monospaced))
                    }

                    // Options
                    HStack(spacing: 20) {
                        Toggle(isOn: $isSensitive) {
                            HStack(spacing: 6) {
                                Text(L10n.AddVariable.sensitiveInfo)
                                    .font(.headline)

                                Image(systemName: "info.circle")
                                    .foregroundStyle(.secondary)
                                    .help(L10n.AddVariable.sensitiveHelp)
                            }
                        }
                        .toggleStyle(.checkbox)

                        Toggle(isOn: $containsShellRef) {
                            HStack(spacing: 6) {
                                Text(L10n.AddVariable.shellReference)
                                    .font(.headline)

                                Image(systemName: "info.circle")
                                    .foregroundStyle(.secondary)
                                    .help(L10n.AddVariable.shellReferenceHelp)
                            }
                        }
                        .toggleStyle(.checkbox)
                    }

                    // Error message
                    if let error = errorMessage {
                        HStack {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundStyle(.red)
                            Text(error)
                                .font(.caption)
                                .foregroundStyle(.red)
                        }
                        .padding()
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color.red.opacity(0.1))
                        .cornerRadius(8)
                    }
                }
                .padding()
            }

            Divider()

            // Footer
            HStack {
                Spacer()

                Button(L10n.General.cancel) {
                    isPresented = false
                }
                .keyboardShortcut(.cancelAction)

                Button(L10n.EditVariable.saveButton) {
                    saveVariable()
                }
                .keyboardShortcut(.defaultAction)
                .disabled(!canSave)
            }
            .padding()
        }
        .frame(width: 500, height: 320)
        .onAppear {
            key = variable.key
            value = variable.value
            isSensitive = variable.isSensitive
            containsShellRef = !variable.isLiteral
        }
    }

    // MARK: - Actions

    private func validateKey() {
        guard !key.isEmpty else {
            errorMessage = nil
            return
        }

        if !isKeyValid {
            errorMessage = L10n.AddVariable.nameFormatError
        } else if keyAlreadyExists {
            errorMessage = L10n.AddVariable.nameExists
        } else {
            errorMessage = nil
        }
    }

    private func saveVariable() {
        guard canSave else { return }

        viewModel.updateVariable(
            in: group.id,
            variableId: variable.id,
            key: key,
            value: value,
            isLiteral: !containsShellRef
        )

        // If sensitivity changed, toggle it
        if isSensitive != variable.isSensitive {
            viewModel.toggleSensitive(in: group.id, variableId: variable.id)
        }

        isPresented = false
    }
}

// MARK: - Preview

#Preview {
    EditVariableSheet(
        variable: EnvVariable(key: "NODE_ENV", value: "development"),
        group: EnvGroup(name: "Sample", variables: []),
        isPresented: .constant(true)
    )
    .environmentObject(EnvGroupViewModel())
}
