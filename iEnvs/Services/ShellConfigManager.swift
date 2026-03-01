import Foundation

/// 解析出的环境变量结构
struct ParsedExportVariable: Identifiable, Equatable {
    let id = UUID()
    let key: String
    let value: String
    let rawLine: String
    let lineNumber: Int
    let isInManagedSection: Bool
}

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

    // MARK: - Parse Existing Exports

    /// 解析现有shell配置文件中的非管理export语句
    func parseExistingExports(shellType: ShellType) -> [ParsedExportVariable] {
        let configPath = ShellConfigManager.getConfigFilePath(for: shellType)

        guard fileManager.fileExists(atPath: configPath),
              let content = try? String(contentsOfFile: configPath, encoding: .utf8) else {
            return []
        }

        let lines = content.components(separatedBy: .newlines)
        var variables: [ParsedExportVariable] = []
        var inManagedSection = false
        var lineNumber = 0

        for line in lines {
            lineNumber += 1

            // 检测管理区域边界
            if line.contains(Marker.sectionStart) {
                inManagedSection = true
                continue
            }
            if line.contains(Marker.sectionEnd) {
                inManagedSection = false
                continue
            }

            // 解析export语句
            if let variable = parseExportLine(line, lineNumber: lineNumber, isInManagedSection: inManagedSection) {
                // 只返回非管理区域的变量
                if !inManagedSection {
                    variables.append(variable)
                }
            }
        }

        return variables
    }

    /// 解析单行export语句
    private func parseExportLine(_ line: String, lineNumber: Int, isInManagedSection: Bool) -> ParsedExportVariable? {
        let trimmed = line.trimmingCharacters(in: .whitespaces)

        // 必须以export开头
        guard trimmed.hasPrefix("export ") else {
            return nil
        }

        // 提取 export 后的内容
        let exportContent = String(trimmed.dropFirst(7)).trimmingCharacters(in: .whitespaces)

        // 找到第一个等号的位置
        guard let equalIndex = exportContent.firstIndex(of: "=") else {
            return nil
        }

        let key = String(exportContent[..<equalIndex]).trimmingCharacters(in: .whitespaces)
        var value = String(exportContent[exportContent.index(after: equalIndex)...]).trimmingCharacters(in: .whitespaces)

        // 验证key格式
        guard isValidKey(key) else {
            return nil
        }

        // 处理引号
        value = unquoteValue(value)

        return ParsedExportVariable(
            key: key,
            value: value,
            rawLine: line,
            lineNumber: lineNumber,
            isInManagedSection: isInManagedSection
        )
    }

    /// 验证环境变量名格式
    private func isValidKey(_ key: String) -> Bool {
        let pattern = "^[a-zA-Z_][a-zA-Z0-9_]*$"
        guard let regex = try? NSRegularExpression(pattern: pattern) else {
            return false
        }
        let range = NSRange(key.startIndex..., in: key)
        return regex.firstMatch(in: key, options: [], range: range) != nil
    }

    /// 去除值的引号
    private func unquoteValue(_ value: String) -> String {
        var result = value

        // 处理双引号
        if result.hasPrefix("\"") && result.hasSuffix("\"") && result.count > 1 {
            result = String(result.dropFirst().dropLast())
            // 处理转义字符
            result = result.replacingOccurrences(of: "\\\"", with: "\"")
            result = result.replacingOccurrences(of: "\\\\", with: "\\")
            result = result.replacingOccurrences(of: "\\$", with: "$")
            result = result.replacingOccurrences(of: "\\`", with: "`")
        }
        // 处理单引号
        else if result.hasPrefix("'") && result.hasSuffix("'") && result.count > 1 {
            result = String(result.dropFirst().dropLast())
        }

        return result
    }

    // MARK: - Remove Existing Export

    /// 从shell配置文件中删除指定行
    func removeExportLine(lineNumber: Int, shellType: ShellType) throws {
        let configPath = ShellConfigManager.getConfigFilePath(for: shellType)

        // 备份原文件
        try BackupManager.shared.backup(filePath: configPath)

        guard let content = try? String(contentsOfFile: configPath, encoding: .utf8) else {
            throw ShellConfigError.fileNotFound(configPath)
        }

        var lines = content.components(separatedBy: .newlines)

        // 验证行号范围
        guard lineNumber > 0 && lineNumber <= lines.count else {
            throw ShellConfigError.invalidLineNumber(lineNumber)
        }

        // 删除指定行（lineNumber是1-based）
        lines.remove(at: lineNumber - 1)

        // 写回文件
        let newContent = lines.joined(separator: "\n")
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

// MARK: - Error Types

enum ShellConfigError: LocalizedError {
    case fileNotFound(String)
    case invalidLineNumber(Int)

    var errorDescription: String? {
        switch self {
        case .fileNotFound(let path):
            return "找不到配置文件: \(path)"
        case .invalidLineNumber(let line):
            return "无效的行号: \(line)"
        }
    }
}
