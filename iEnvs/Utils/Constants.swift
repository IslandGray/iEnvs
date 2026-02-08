import Foundation

enum Constants {
    static let appVersion = "1.0.0"

    enum Markers {
        static let sectionStart = "# ========== iEnvs Managed Variables =========="
        static let sectionEnd = "# ========== End of iEnvs Managed Variables =========="
        static let warning = "# 警告：请勿手动编辑此区域"
        static let generator = "# 由 iEnvs 自动管理 - https://github.com/yourname/ienvs"

        static func groupStart(id: UUID, name: String) -> String {
            "# [iEnvs:\(id.uuidString)] START - \(name)"
        }

        static func groupEnd(id: UUID, name: String) -> String {
            "# [iEnvs:\(id.uuidString)] END - \(name)"
        }
    }

    enum Paths {
        static var appSupportDirectory: URL {
            let fileManager = FileManager.default
            let appSupportDir = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
            return appSupportDir.appendingPathComponent("iEnvs", isDirectory: true)
        }

        static var dataFileURL: URL {
            appSupportDirectory.appendingPathComponent("data.json")
        }

        static var backupDirectory: URL {
            appSupportDirectory.appendingPathComponent("backups", isDirectory: true)
        }

        static var logDirectory: URL {
            let fileManager = FileManager.default
            let logsDir = fileManager.urls(for: .libraryDirectory, in: .userDomainMask)[0]
            return logsDir.appendingPathComponent("Logs/iEnvs", isDirectory: true)
        }
    }

    enum Defaults {
        static let maxBackupCount = 10
        static let minBackupCount = 5
        static let maxBackupCountLimit = 20
    }
}
