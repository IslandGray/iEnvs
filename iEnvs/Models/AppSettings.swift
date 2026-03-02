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
    var launchAtLogin: Bool

    init(
        shellType: ShellType = .detectCurrent(),
        configFilePath: String = "",
        autoBackup: Bool = true,
        maxBackupCount: Int = 10,
        theme: ThemeMode = .auto,
        enableConflictDetection: Bool = true,
        enableRegexSearch: Bool = false,
        exportIncludesDisabledGroups: Bool = false,
        language: AppLanguage = .zh,
        launchAtLogin: Bool = false
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
        self.launchAtLogin = launchAtLogin
    }

    // 向后兼容：旧版本数据可能缺少某些字段
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        shellType = try container.decode(ShellType.self, forKey: .shellType)
        configFilePath = try container.decode(String.self, forKey: .configFilePath)
        autoBackup = try container.decodeIfPresent(Bool.self, forKey: .autoBackup) ?? true
        maxBackupCount = try container.decodeIfPresent(Int.self, forKey: .maxBackupCount) ?? 10
        theme = try container.decodeIfPresent(ThemeMode.self, forKey: .theme) ?? .auto
        enableConflictDetection = try container.decodeIfPresent(Bool.self, forKey: .enableConflictDetection) ?? true
        enableRegexSearch = try container.decodeIfPresent(Bool.self, forKey: .enableRegexSearch) ?? false
        exportIncludesDisabledGroups = try container.decodeIfPresent(Bool.self, forKey: .exportIncludesDisabledGroups) ?? false
        language = try container.decodeIfPresent(AppLanguage.self, forKey: .language) ?? .zh
        launchAtLogin = try container.decodeIfPresent(Bool.self, forKey: .launchAtLogin) ?? false
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
