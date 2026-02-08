//
//  AddVariableSheet.swift
//  iEnvs
//
//  Created on 2026-02-08.
//

import SwiftUI

struct AddVariableSheet: View {
    let group: EnvGroup
    @Binding var isPresented: Bool
    @EnvironmentObject var viewModel: EnvGroupViewModel

    @State private var key: String = ""
    @State private var value: String = ""
    @State private var isSensitive: Bool = false
    @State private var showBatchInput: Bool = false
    @State private var batchText: String = ""
    @State private var errorMessage: String?

    private var isKeyValid: Bool {
        Validators.validateEnvKey(key)
    }

    private var keyAlreadyExists: Bool {
        group.variables.contains { $0.key == key }
    }

    private var canSave: Bool {
        !key.isEmpty && isKeyValid && !keyAlreadyExists && !value.isEmpty
    }

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("添加环境变量")
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
                    if showBatchInput {
                        batchInputView
                    } else {
                        singleInputView
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
                Toggle(isOn: $showBatchInput) {
                    Text("批量导入")
                }
                .toggleStyle(.checkbox)
                .help("粘贴多行 KEY=VALUE 格式")

                Spacer()

                Button("取消") {
                    isPresented = false
                }
                .keyboardShortcut(.cancelAction)

                Button(showBatchInput ? "导入" : "添加") {
                    if showBatchInput {
                        saveBatchVariables()
                    } else {
                        saveVariable()
                    }
                }
                .keyboardShortcut(.defaultAction)
                .disabled(!canSave && !showBatchInput)
            }
            .padding()
        }
        .frame(width: 500, height: showBatchInput ? 400 : 300)
    }

    // MARK: - Single Input View

    private var singleInputView: some View {
        VStack(spacing: 16) {
            // Key input
            VStack(alignment: .leading, spacing: 6) {
                Text("变量名")
                    .font(.headline)

                TextField("例如: NODE_ENV", text: $key)
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
                                Text("该变量名已存在")
                                    .font(.caption)
                                    .foregroundStyle(.red)
                            } else {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundStyle(.green)
                                Text("变量名有效")
                                    .font(.caption)
                                    .foregroundStyle(.green)
                            }
                        } else {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundStyle(.red)
                            Text("只能包含字母、数字和下划线，且必须以字母或下划线开头")
                                .font(.caption)
                                .foregroundStyle(.red)
                        }
                    }
                }
            }

            // Value input
            VStack(alignment: .leading, spacing: 6) {
                Text("变量值")
                    .font(.headline)

                TextField("例如: production", text: $value)
                    .textFieldStyle(.roundedBorder)
                    .font(.system(.body, design: .monospaced))
            }

            // Sensitive toggle
            Toggle(isOn: $isSensitive) {
                HStack(spacing: 6) {
                    Text("敏感信息")
                        .font(.headline)

                    Image(systemName: "info.circle")
                        .foregroundStyle(.secondary)
                        .help("敏感信息将在列表中隐藏显示")
                }
            }
            .toggleStyle(.checkbox)
        }
    }

    // MARK: - Batch Input View

    private var batchInputView: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("批量导入")
                .font(.headline)

            Text("每行一个变量，格式: KEY=VALUE")
                .font(.caption)
                .foregroundStyle(.secondary)

            TextEditor(text: $batchText)
                .font(.system(.body, design: .monospaced))
                .frame(minHeight: 200)
                .border(Color.secondary.opacity(0.3))
                .scrollContentBackground(.hidden)
                .background(Color(nsColor: .textBackgroundColor))

            Text("示例:\nNODE_ENV=production\nAPI_KEY=sk-1234567890\nPORT=3000")
                .font(.caption)
                .foregroundStyle(.tertiary)
                .padding(.top, 4)
        }
    }

    // MARK: - Actions

    private func validateKey() {
        guard !key.isEmpty else {
            errorMessage = nil
            return
        }

        if !isKeyValid {
            errorMessage = "变量名格式不正确"
        } else if keyAlreadyExists {
            errorMessage = "变量名已存在"
        } else {
            errorMessage = nil
        }
    }

    private func saveVariable() {
        guard canSave else { return }

        viewModel.addVariable(to: group.id, key: key, value: value)
        // If marked as sensitive, toggle it after adding
        if isSensitive, let addedGroup = viewModel.groups.first(where: { $0.id == group.id }),
           let addedVar = addedGroup.variables.last(where: { $0.key == key }) {
            viewModel.toggleSensitive(in: group.id, variableId: addedVar.id)
        }
        isPresented = false
    }

    private func saveBatchVariables() {
        let lines = batchText.components(separatedBy: .newlines)
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty && !$0.hasPrefix("#") }

        var addedCount = 0
        var errors: [String] = []

        for line in lines {
            let parts = line.components(separatedBy: "=")
            guard parts.count >= 2 else {
                errors.append("格式错误: \(line)")
                continue
            }

            let key = parts[0].trimmingCharacters(in: .whitespaces)
            let value = parts.dropFirst().joined(separator: "=").trimmingCharacters(in: .whitespaces)

            guard Validators.validateEnvKey(key) else {
                errors.append("无效的变量名: \(key)")
                continue
            }

            if group.variables.contains(where: { $0.key == key }) {
                errors.append("变量已存在: \(key)")
                continue
            }

            viewModel.addVariable(to: group.id, key: key, value: value)
            addedCount += 1
        }

        if errors.isEmpty {
            isPresented = false
        } else {
            errorMessage = "成功导入 \(addedCount) 个变量\n错误: \(errors.joined(separator: "\n"))"
        }
    }
}

// MARK: - Preview

#Preview {
    AddVariableSheet(
        group: EnvGroup(name: "示例分组", variables: []),
        isPresented: .constant(true)
    )
    .environmentObject(EnvGroupViewModel())
}
