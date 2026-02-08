import SwiftUI

struct GroupRowView: View {
    let group: EnvGroup
    @EnvironmentObject var viewModel: EnvGroupViewModel

    var hasConflict: Bool {
        viewModel.conflicts.contains { conflict in
            conflict.affectedGroupIDs.contains(group.id)
        }
    }

    var body: some View {
        HStack(spacing: 12) {
            // Toggle switch for enabling/disabling group
            Toggle("", isOn: Binding(
                get: { group.isEnabled },
                set: { newValue in
                    viewModel.toggleGroup(id: group.id)
                }
            ))
            .toggleStyle(.switch)
            .labelsHidden()

            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(group.name)
                        .font(.headline)
                        .foregroundStyle(.primary)

                    if hasConflict {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundStyle(.yellow)
                            .help("此分组存在变量冲突")
                    }
                }

                Text("\(group.variables.count) 个变量")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    List {
        GroupRowView(group: EnvGroup(
            name: "前端开发",
            description: "Node.js 环境",
            isEnabled: true,
            variables: [
                EnvVariable(key: "NODE_ENV", value: "development"),
                EnvVariable(key: "API_KEY", value: "secret", isSensitive: true)
            ]
        ))
        .environmentObject(EnvGroupViewModel())

        GroupRowView(group: EnvGroup(
            name: "后端开发",
            description: "Python 环境",
            isEnabled: false,
            variables: []
        ))
        .environmentObject(EnvGroupViewModel())
    }
}
