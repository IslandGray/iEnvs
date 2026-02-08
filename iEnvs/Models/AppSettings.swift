import Foundation

struct AppSettings: Codable, Equatable {
    var shellType: ShellType
    var configFilePath: String
    var autoBackup: Bool
    var maxBackupCount: Int
    var theme: ThemeMode
    var enableConflictDetection: Bool
    var enableRegexSearch: Bool
    var exportIncludesDisabledGroups: Bool

    init(
        shellType: ShellType = .detectCurrent(),
        configFilePath: String = "",
        autoBackup: Bool = true,
        maxBackupCount: Int = 10,
        theme: ThemeMode = .auto,
        enableConflictDetection: Bool = true,
        enableRegexSearch: Bool = false,
        exportIncludesDisabledGroups: Bool = false
    ) {
        self.shellType = shellType
        self.configFilePath = configFilePath.isEmpty ? shellType.defaultConfigPath : configFilePath
        self.autoBackup = autoBackup
        self.maxBackupCount = max(5, min(20, maxBackupCount))
        self.theme = theme
        self.enableConflictDetection = enableConflictDetection
        self.enableRegexSearch = enableRegexSearch
        self.exportIncludesDisabledGroups = exportIncludesDisabledGroups
    }
}

enum ThemeMode: String, Codable, CaseIterable, Identifiable {
    case auto
    case light
    case dark

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .auto: return "自动"
        case .light: return "浅色"
        case .dark: return "深色"
        }
    }
}
