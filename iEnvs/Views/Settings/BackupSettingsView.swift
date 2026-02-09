import SwiftUI

struct BackupSettingsView: View {
    @ObservedObject var viewModel: SettingsViewModel
    @State private var selectedBackup: BackupFile?
    @State private var showDeleteConfirmation = false

    var body: some View {
        Form {
            Section {
                VStack(alignment: .leading, spacing: 20) {
                    // Auto backup toggle
                    autoBackupSection

                    Divider()

                    // Max backup count
                    maxBackupCountSection

                    Divider()

                    // Backup list
                    backupListSection
                }
                .padding()
            }
        }
        .formStyle(.grouped)
        .alert(L10n.Settings.deleteBackupTitle, isPresented: $showDeleteConfirmation) {
            Button(L10n.General.cancel, role: .cancel) {}
            Button(L10n.General.delete, role: .destructive) {
                deleteSelectedBackup()
            }
        } message: {
            Text(L10n.Settings.deleteBackupConfirm)
        }
    }

    // MARK: - Auto Backup Section

    private var autoBackupSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Toggle(isOn: $viewModel.settings.autoBackup) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(L10n.Settings.autoBackup)
                        .font(.headline)

                    Text(L10n.Settings.autoBackupDesc)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .toggleStyle(.checkbox)
        }
    }

    // MARK: - Max Backup Count Section

    private var maxBackupCountSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(L10n.Settings.maxBackupCount)
                .font(.headline)

            HStack {
                Stepper(
                    value: $viewModel.settings.maxBackupCount,
                    in: 5...20,
                    step: 1
                ) {
                    HStack {
                        Text(L10n.Settings.keepRecent)
                        Text("\(viewModel.settings.maxBackupCount)")
                            .fontWeight(.medium)
                            .foregroundColor(.blue)
                        Text(L10n.Settings.backupsUnit)
                    }
                }

                Spacer()
            }

            Text(L10n.Settings.autoDeleteNote)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }

    // MARK: - Backup List Section

    private var backupListSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(L10n.Settings.backupList)
                    .font(.headline)

                Spacer()

                Button(action: { viewModel.refreshBackups() }) {
                    Label(L10n.General.refresh, systemImage: "arrow.clockwise")
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
            }

            if viewModel.backups.isEmpty {
                VStack(spacing: 8) {
                    Image(systemName: "archivebox")
                        .font(.system(size: 32))
                        .foregroundStyle(.secondary)

                    Text(L10n.Settings.noBackups)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 40)
                .background(Color(nsColor: .controlBackgroundColor))
                .cornerRadius(8)
            } else {
                VStack(spacing: 0) {
                    // Backup list
                    List(viewModel.backups, selection: $selectedBackup) { backup in
                        BackupRowView(backup: backup)
                            .tag(backup)
                    }
                    .frame(height: 200)
                    .border(Color.secondary.opacity(0.3))

                    // Action buttons
                    HStack {
                        Button(action: restoreSelectedBackup) {
                            Label(L10n.Settings.restoreBackup, systemImage: "clock.arrow.circlepath")
                        }
                        .disabled(selectedBackup == nil)

                        Button(action: { showDeleteConfirmation = true }) {
                            Label(L10n.General.delete, systemImage: "trash")
                        }
                        .disabled(selectedBackup == nil)

                        Spacer()

                        Text(L10n.Settings.backupCount(viewModel.backups.count))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.top, 8)
                }
            }
        }
    }

    // MARK: - Actions

    private func restoreSelectedBackup() {
        guard let backup = selectedBackup else { return }
        viewModel.restoreBackup(backup)
    }

    private func deleteSelectedBackup() {
        guard let backup = selectedBackup else { return }
        viewModel.deleteBackup(backup)
        selectedBackup = nil
    }
}

// MARK: - Backup Row View

struct BackupRowView: View {
    let backup: BackupFile

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(backup.displayName)
                    .font(.system(.body, design: .monospaced))
                    .lineLimit(1)

                HStack(spacing: 12) {
                    Label(formatDate(backup.createdAt), systemImage: "clock")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    Label(backup.formattedSize, systemImage: "doc")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            Spacer()
        }
        .padding(.vertical, 4)
    }

    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        return formatter.string(from: date)
    }
}

// MARK: - Preview

#Preview {
    BackupSettingsView(viewModel: SettingsViewModel())
        .frame(width: 600, height: 400)
}
