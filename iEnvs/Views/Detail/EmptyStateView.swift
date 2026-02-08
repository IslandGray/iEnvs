//
//  EmptyStateView.swift
//  iEnvs
//
//  Created on 2026-02-08.
//

import SwiftUI

struct EmptyStateView: View {
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "tray")
                .font(.system(size: 50))
                .foregroundStyle(.secondary)

            VStack(spacing: 4) {
                Text("此分组暂无环境变量")
                    .font(.headline)
                    .foregroundStyle(.primary)

                Text("点击 + 按钮添加环境变量")
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
