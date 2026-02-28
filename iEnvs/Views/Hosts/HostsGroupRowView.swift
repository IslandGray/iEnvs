import SwiftUI

struct HostsGroupRowView: View {
    let group: HostGroup
    @EnvironmentObject var viewModel: HostsGroupViewModel

    var hasConflict: Bool {
        viewModel.hostsConflicts.contains { conflict in
            conflict.affectedGroupIDs.contains(group.id)
        }
    }

    var body: some View {
        HStack(spacing: 12) {
            Toggle("", isOn: Binding(
                get: { group.isEnabled },
                set: { _ in
                    viewModel.toggleHostsGroup(id: group.id)
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
                            .help(L10n.Hosts.conflictWarning)
                    }
                }

                Text(L10n.Hosts.entryCount(group.entries.count))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()
        }
        .padding(.vertical, 4)
    }
}
