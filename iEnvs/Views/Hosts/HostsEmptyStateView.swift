import SwiftUI

struct HostsEmptyStateView: View {
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "network")
                .font(.system(size: 50))
                .foregroundStyle(.secondary)

            VStack(spacing: 4) {
                Text(L10n.Hosts.noEntries)
                    .font(.headline)
                    .foregroundStyle(.primary)

                Text(L10n.Hosts.addEntryHint)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
