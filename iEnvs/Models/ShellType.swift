import Foundation

enum ShellType: String, Codable, CaseIterable, Identifiable {
    case bash
    case zsh

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .bash: return "Bash"
        case .zsh: return "Zsh"
        }
    }

    var defaultConfigPath: String {
        let homeDir = FileManager.default.homeDirectoryForCurrentUser.path
        switch self {
        case .bash:
            let bashrc = "\(homeDir)/.bashrc"
            let bashProfile = "\(homeDir)/.bash_profile"
            return FileManager.default.fileExists(atPath: bashrc) ? bashrc : bashProfile
        case .zsh:
            return "\(homeDir)/.zshrc"
        }
    }

    static func detectCurrent() -> ShellType {
        let shellPath = ProcessInfo.processInfo.environment["SHELL"] ?? ""
        if shellPath.contains("zsh") {
            return .zsh
        } else if shellPath.contains("bash") {
            return .bash
        } else {
            return .zsh
        }
    }
}
