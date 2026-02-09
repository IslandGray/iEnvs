import Foundation
import AppKit

enum AppLanguage: String, Codable, CaseIterable, Identifiable {
    case zh = "zh"
    case en = "en"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .zh: return "中文"
        case .en: return "English"
        }
    }
}

struct AppSettings: Codable, Equatable {
    var shellType: ShellType
    var configFilePath: String
    var autoBackup: Bool
    var maxBackupCount: Int
    var theme: ThemeMode
    var enableConflictDetection: Bool
    var enableRegexSearch: Bool
    var exportIncludesDisabledGroups: Bool
    var language: AppLanguage

    init(
        shellType: ShellType = .detectCurrent(),
        configFilePath: String = "",
        autoBackup: Bool = true,
        maxBackupCount: Int = 10,
        theme: ThemeMode = .auto,
        enableConflictDetection: Bool = true,
        enableRegexSearch: Bool = false,
        exportIncludesDisabledGroups: Bool = false,
        language: AppLanguage = .zh
    ) {
        self.shellType = shellType
        self.configFilePath = configFilePath.isEmpty ? shellType.defaultConfigPath : configFilePath
        self.autoBackup = autoBackup
        self.maxBackupCount = max(5, min(20, maxBackupCount))
        self.theme = theme
        self.enableConflictDetection = enableConflictDetection
        self.enableRegexSearch = enableRegexSearch
        self.exportIncludesDisabledGroups = exportIncludesDisabledGroups
        self.language = language
    }
}

enum ThemeMode: String, Codable, CaseIterable, Identifiable {
    case auto
    case light
    case dark

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .auto: return L10n.Settings.themeAuto
        case .light: return L10n.Settings.themeLight
        case .dark: return L10n.Settings.themeDark
        }
    }

    var nsAppearance: NSAppearance? {
        switch self {
        case .auto: return nil
        case .light: return NSAppearance(named: .aqua)
        case .dark: return NSAppearance(named: .darkAqua)
        }
    }
}
