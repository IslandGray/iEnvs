import Foundation

struct BackupFile: Identifiable, Hashable {
    let id: UUID
    let path: String
    let displayName: String
    let createdAt: Date
    let fileSize: Int64

    init(path: String, displayName: String, createdAt: Date, fileSize: Int64) {
        self.id = UUID()
        self.path = path
        self.displayName = displayName
        self.createdAt = createdAt
        self.fileSize = fileSize
    }

    var formattedSize: String {
        ByteCountFormatter.string(fromByteCount: fileSize, countStyle: .file)
    }
}

final class BackupManager {
    // MARK: - Singleton
    static let shared = BackupManager()

    // MARK: - Properties
    private let fileManager = FileManager.default
    private let backupDir: URL

    // MARK: - Initialization
    private init() {
        let appSupportDir = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        self.backupDir = appSupportDir.appendingPathComponent("iEnvs/backups", isDirectory: true)

        try? fileManager.createDirectory(at: backupDir, withIntermediateDirectories: true)
    }

    // MARK: - Public Methods

    /// 备份指定文件
    func backup(filePath: String) throws {
        let sourceURL = URL(fileURLWithPath: filePath)

        guard fileManager.fileExists(atPath: filePath) else {
            return
        }

        let fileName = sourceURL.lastPathComponent
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyyMMdd_HHmmss"
        let timestamp = dateFormatter.string(from: Date())
        let backupFileName = "\(fileName).\(timestamp).bak"
        let backupURL = backupDir.appendingPathComponent(backupFileName)

        try fileManager.copyItem(at: sourceURL, to: backupURL)

        // 自动清理旧备份
        try cleanOldBackups(maxCount: 10)
    }

    /// 清理旧备份，保留最新的 maxCount 个
    func cleanOldBackups(maxCount: Int) throws {
        let backups = try listBackups()

        guard backups.count > maxCount else {
            return
        }

        let toDelete = backups.dropFirst(maxCount)
        for backup in toDelete {
            try fileManager.removeItem(at: URL(fileURLWithPath: backup.path))
        }
    }

    /// 列出所有备份
    func listBackups() -> [(path: String, date: Date)] {
        do {
            let contents = try fileManager.contentsOfDirectory(
                at: backupDir,
                includingPropertiesForKeys: [.creationDateKey]
            )

            let backups = contents.compactMap { url -> (path: String, date: Date)? in
                guard url.pathExtension == "bak",
                      let attributes = try? fileManager.attributesOfItem(atPath: url.path),
                      let creationDate = attributes[.creationDate] as? Date else {
                    return nil
                }

                return (path: url.path, date: creationDate)
            }

            return backups.sorted { $0.date > $1.date }
        } catch {
            print("BackupManager.listBackups() error: \(error.localizedDescription)")
            return []
        }
    }

    /// 恢复备份
    func restoreBackup(backupPath: String, toPath: String) throws {
        let backupURL = URL(fileURLWithPath: backupPath)
        let targetURL = URL(fileURLWithPath: toPath)

        // 先备份当前文件
        if fileManager.fileExists(atPath: toPath) {
            try backup(filePath: toPath)
        }

        // 替换为备份文件
        if fileManager.fileExists(atPath: toPath) {
            try fileManager.removeItem(at: targetURL)
        }
        try fileManager.copyItem(at: backupURL, to: targetURL)
    }
}
