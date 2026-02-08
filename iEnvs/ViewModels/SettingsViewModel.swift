import Foundation
import SwiftUI

@MainActor
final class SettingsViewModel: ObservableObject {
    // MARK: - Published Properties
    @Published var settings: AppSettings
    @Published var backups: [BackupFile] = []

    // MARK: - Dependencies
    private let dataStore = DataStore.shared
    private let backupManager = BackupManager.shared

    // MARK: - Computed Properties
    var detectedShellType: ShellType {
        ShellType.detectCurrent()
    }

    // MARK: - Initialization
    init() {
        let appData = dataStore.load()
        settings = appData.settings
        refreshBackups()
    }

    // MARK: - Public Methods

    /// 保存设置到 DataStore
    func saveSettings() {
        var appData = dataStore.load()
        appData.settings = settings
        dataStore.save(appData)
    }

    /// 自动检测 Shell 类型并更新设置
    func autoDetectShell() {
        let detected = ShellType.detectCurrent()
        settings.shellType = detected
        settings.configFilePath = ShellConfigManager.getConfigFilePath(for: detected)
        saveSettings()
    }

    /// 刷新备份列表
    func refreshBackups() {
        let rawBackups = backupManager.listBackups()
        backups = rawBackups.map { backup in
            let url = URL(fileURLWithPath: backup.path)
            let size: Int64 = (try? FileManager.default.attributesOfItem(atPath: backup.path)[.size] as? Int64) ?? 0
            return BackupFile(
                path: backup.path,
                displayName: url.lastPathComponent,
                createdAt: backup.date,
                fileSize: size
            )
        }
    }

    /// 恢复备份
    func restoreBackup(_ backup: BackupFile) {
        do {
            try backupManager.restoreBackup(backupPath: backup.path, toPath: settings.configFilePath)
            refreshBackups()
        } catch {
            Logger.shared.error("Failed to restore backup: \(error.localizedDescription)")
        }
    }

    /// 删除备份
    func deleteBackup(_ backup: BackupFile) {
        do {
            try FileManager.default.removeItem(atPath: backup.path)
            refreshBackups()
        } catch {
            Logger.shared.error("Failed to delete backup: \(error.localizedDescription)")
        }
    }

    /// 自动检测 Shell 类型
    func detectShell() -> ShellType {
        ShellType.detectCurrent()
    }

    /// 更新 Shell 类型
    func updateShellType(_ shellType: ShellType) {
        settings.shellType = shellType
        settings.configFilePath = ShellConfigManager.getConfigFilePath(for: shellType)
        saveSettings()
    }

    /// 更新配置文件路径
    func updateConfigFilePath(_ path: String) {
        settings.configFilePath = path
        saveSettings()
    }

    /// 更新自动备份设置
    func updateAutoBackup(_ enabled: Bool) {
        settings.autoBackup = enabled
        saveSettings()
    }

    /// 更新最大备份数量
    func updateMaxBackupCount(_ count: Int) {
        settings.maxBackupCount = max(5, min(20, count))
        saveSettings()
    }

    /// 更新主题模式
    func updateTheme(_ theme: ThemeMode) {
        settings.theme = theme
        saveSettings()
    }

    /// 更新冲突检测设置
    func updateConflictDetection(_ enabled: Bool) {
        settings.enableConflictDetection = enabled
        saveSettings()
    }

    /// 更新正则搜索设置
    func updateRegexSearch(_ enabled: Bool) {
        settings.enableRegexSearch = enabled
        saveSettings()
    }

    /// 更新导出设置
    func updateExportIncludesDisabledGroups(_ enabled: Bool) {
        settings.exportIncludesDisabledGroups = enabled
        saveSettings()
    }

    /// 重置所有设置为默认值
    func resetToDefaults() {
        settings = AppSettings()
        saveSettings()
    }

    /// 验证配置文件是否存在
    func validateConfigFile() -> Bool {
        FileManager.default.fileExists(atPath: settings.configFilePath)
    }

    /// 获取配置文件信息
    func getConfigFileInfo() -> (size: String, modifiedDate: String)? {
        guard let attributes = try? FileManager.default.attributesOfItem(atPath: settings.configFilePath),
              let fileSize = attributes[.size] as? Int64,
              let modifiedDate = attributes[.modificationDate] as? Date else {
            return nil
        }

        let sizeString = ByteCountFormatter.string(fromByteCount: fileSize, countStyle: .file)

        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .medium
        dateFormatter.timeStyle = .medium
        let dateString = dateFormatter.string(from: modifiedDate)

        return (size: sizeString, modifiedDate: dateString)
    }
}
