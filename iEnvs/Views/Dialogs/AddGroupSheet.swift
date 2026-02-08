import SwiftUI

struct AddGroupSheet: View {
    @EnvironmentObject var viewModel: EnvGroupViewModel
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
            Text("添加新分组")
                .font(.title2)
                .bold()

            // Form
            VStack(alignment: .leading, spacing: 16) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("分组名称")
                        .font(.headline)

                    TextField("例如：前端开发", text: $groupName)
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
                    Text("描述（可选）")
                        .font(.headline)

                    TextField("例如：Node.js 项目环境变量", text: $groupDescription)
                        .textFieldStyle(.roundedBorder)
                }
            }
            .padding()
            .background(Color(.controlBackgroundColor))
            .cornerRadius(8)

            // Buttons
            HStack {
                Button("取消") {
                    dismiss()
                }
                .keyboardShortcut(.cancelAction)

                Spacer()

                Button("确认") {
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

        // Check if name is too long
        if trimmedName.count > 100 {
            validationError = "分组名称不能超过 100 个字符"
            return
        }

        // Check if name already exists
        if viewModel.groups.contains(where: { $0.name == trimmedName }) {
            validationError = "该分组名称已存在"
            return
        }

        validationError = nil
    }

    private func addGroup() {
        let trimmedName = groupName.trimmingCharacters(in: .whitespaces)
        let trimmedDescription = groupDescription.trimmingCharacters(in: .whitespaces)

        viewModel.addGroup(name: trimmedName, description: trimmedDescription)
        dismiss()
    }
}

#Preview {
    AddGroupSheet()
        .environmentObject(EnvGroupViewModel())
}
