import SwiftUI

struct EmptyStateView: View {
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "tray")
                .font(.system(size: 50))
                .foregroundStyle(.secondary)

            VStack(spacing: 4) {
                Text(L10n.EmptyState.noVariables)
                    .font(.headline)
                    .foregroundStyle(.primary)

                Text(L10n.EmptyState.addVariableHint)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - Preview

#Preview {
    EmptyStateView()
        .frame(width: 400, height: 300)
}
