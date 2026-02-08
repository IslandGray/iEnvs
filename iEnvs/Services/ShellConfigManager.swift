import Foundation

final class ShellConfigManager {
    // MARK: - Constants
    private enum Marker {
        static let sectionStart = "# ========== iEnvs Managed Variables =========="
        static let sectionEnd = "# ========== End of iEnvs Managed Variables =========="
        static let warning = "# WARNING: This section is managed by iEnvs. Do not edit manually."

        static func groupStart(id: UUID, name: String) -> String {
            "# [iEnvs:\(id.uuidString)] START - \(name)"
        }

        static func groupEnd(id: UUID, name: String) -> String {
            "# [iEnvs:\(id.uuidString)] END - \(name)"
        }
    }

    // MARK: - Properties
    private let fileManager = FileManager.default

    // MARK: - Public Methods

    /// 检测当前 Shell 类型
    static func detectShellType() -> ShellType {
        let shellPath = ProcessInfo.processInfo.environment["SHELL"] ?? ""
        if shellPath.contains("zsh") {
            return .zsh
        } else if shellPath.contains("bash") {
            return .bash
        } else {
            return .zsh
        }
    }

    /// 获取配置文件路径
    static func getConfigFilePath(for shellType: ShellType) -> String {
        let homeDir = FileManager.default.homeDirectoryForCurrentUser.path
        switch shellType {
        case .bash:
            let bashrc = "\(homeDir)/.bashrc"
            let bashProfile = "\(homeDir)/.bash_profile"
            return FileManager.default.fileExists(atPath: bashrc) ? bashrc : bashProfile
        case .zsh:
            return "\(homeDir)/.zshrc"
        }
    }

    /// 同步分组到 Shell 配置文件
    func syncToShellConfig(groups: [EnvGroup], shellType: ShellType) throws {
        let configPath = ShellConfigManager.getConfigFilePath(for: shellType)

        // 1. 备份原文件
        try BackupManager.shared.backup(filePath: configPath)

        // 2. 读取配置文件
        let originalContent: String
        if fileManager.fileExists(atPath: configPath) {
            originalContent = try String(contentsOfFile: configPath, encoding: .utf8)
        } else {
            originalContent = ""
        }

        // 3. 生成新的 iEnvs 管理区域
        let managedSection = generateManagedSection(from: groups)

        // 4. 替换或插入管理区域
        let newContent = replaceManagedSection(in: originalContent, with: managedSection)

        // 5. 写回文件
        try newContent.write(toFile: configPath, atomically: true, encoding: .utf8)
    }

    // MARK: - Private Methods

    /// 生成 iEnvs 管理区域内容
    private func generateManagedSection(from groups: [EnvGroup]) -> String {
        let enabledGroups = groups.filter { $0.isEnabled }.sorted { $0.order < $1.order }

        guard !enabledGroups.isEmpty else {
            return ""
        }

        var lines: [String] = []

        // 区域头部
        lines.append(Marker.sectionStart)
        lines.append(Marker.warning)
        lines.append("")

        // 每个分组
        for group in enabledGroups {
            lines.append(Marker.groupStart(id: group.id, name: group.name))

            for variable in group.variables {
                let exportLine = generateExportLine(key: variable.key, value: variable.value)
                lines.append(exportLine)
            }

            lines.append(Marker.groupEnd(id: group.id, name: group.name))
            lines.append("")
        }

        // 区域尾部
        lines.append(Marker.sectionEnd)

        return lines.joined(separator: "\n")
    }

    /// 生成 export 语句
    private func generateExportLine(key: String, value: String) -> String {
        // 转义值中的特殊字符
        let escapedValue = value
            .replacingOccurrences(of: "\\", with: "\\\\")
            .replacingOccurrences(of: "\"", with: "\\\"")
            .replacingOccurrences(of: "$", with: "\\$")
            .replacingOccurrences(of: "`", with: "\\`")

        return "export \(key)=\"\(escapedValue)\""
    }

    /// 替换配置文件中的 iEnvs 管理区域
    private func replaceManagedSection(in content: String, with newSection: String) -> String {
        let lines = content.components(separatedBy: .newlines)
        var result: [String] = []
        var inManagedSection = false
        var foundSection = false

        for line in lines {
            if line.contains(Marker.sectionStart) {
                inManagedSection = true
                foundSection = true

                // 插入新的管理区域
                if !newSection.isEmpty {
                    result.append(newSection)
                }

                continue
            }

            if line.contains(Marker.sectionEnd) {
                inManagedSection = false
                continue
            }

            if !inManagedSection {
                result.append(line)
            }
        }

        // 如果没有找到管理区域，在文件末尾添加
        if !foundSection && !newSection.isEmpty {
            result.append("")
            result.append(newSection)
        }

        return result.joined(separator: "\n")
    }
}
