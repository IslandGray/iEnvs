import Foundation

final class HostsFileManager {
    // MARK: - Constants
    private enum Marker {
        static let sectionStart = Constants.HostsMarkers.sectionStart
        static let sectionEnd = Constants.HostsMarkers.sectionEnd
        static let warning = Constants.HostsMarkers.warning

        static func groupStart(id: UUID, name: String) -> String {
            Constants.HostsMarkers.groupStart(id: id, name: name)
        }

        static func groupEnd(id: UUID, name: String) -> String {
            Constants.HostsMarkers.groupEnd(id: id, name: name)
        }
    }

    // MARK: - Properties
    private let hostsPath = Constants.HostsMarkers.hostsFilePath
    private let fileManager = FileManager.default

    // MARK: - Public Methods

    /// 同步分组到 /etc/hosts 文件
    func syncToHostsFile(groups: [HostGroup]) throws {
        // 1. 读取当前 hosts 文件
        let originalContent: String
        if fileManager.fileExists(atPath: hostsPath) {
            originalContent = try String(contentsOfFile: hostsPath, encoding: .utf8)
        } else {
            originalContent = ""
        }

        // 2. 生成新的管理区域
        let managedSection = generateManagedSection(from: groups)

        // 3. 替换管理区域
        let newContent = replaceManagedSection(in: originalContent, with: managedSection)

        // 4. 使用管理员权限写入
        try writeWithPrivilege(content: newContent, to: hostsPath)

        // 5. 刷新 DNS 缓存
        try flushDNSCache()
    }

    /// 刷新 DNS 缓存
    func flushDNSCache() throws {
        let script = """
        do shell script "dscacheutil -flushcache && killall -HUP mDNSResponder" with administrator privileges
        """
        try executeAppleScript(script)
    }

    /// 解析 /etc/hosts 中非管理区域的现有条目
    func parseExistingHosts() -> [(entry: HostEntry, lineNumber: Int)] {
        guard let content = try? String(contentsOfFile: hostsPath, encoding: .utf8) else {
            return []
        }

        let lines = content.components(separatedBy: .newlines)
        var entries: [(entry: HostEntry, lineNumber: Int)] = []
        var inManagedSection = false
        var lineNumber = 0

        for line in lines {
            lineNumber += 1

            if line.contains(Marker.sectionStart) {
                inManagedSection = true
                continue
            }
            if line.contains(Marker.sectionEnd) {
                inManagedSection = false
                continue
            }

            if !inManagedSection {
                if let entry = parseHostsLine(line) {
                    entries.append((entry, lineNumber))
                }
            }
        }

        return entries
    }

    /// 从 /etc/hosts 中删除指定行
    func removeHostsLine(lineNumber: Int) throws {
        // 备份原文件（使用管理员权限复制）
        let backupScript = """
        do shell script "cp '\(hostsPath)' '\(hostsPath).backup.\(Int(Date().timeIntervalSince1970))'" with administrator privileges
        """
        try executeAppleScript(backupScript)

        guard let content = try? String(contentsOfFile: hostsPath, encoding: .utf8) else {
            throw HostsFileError.fileNotFound
        }

        var lines = content.components(separatedBy: .newlines)

        // 验证行号范围
        guard lineNumber > 0 && lineNumber <= lines.count else {
            throw HostsFileError.invalidLineNumber(lineNumber)
        }

        // 删除指定行
        lines.remove(at: lineNumber - 1)

        // 写回文件
        let newContent = lines.joined(separator: "\n")
        try writeWithPrivilege(content: newContent, to: hostsPath)

        // 刷新DNS缓存
        try flushDNSCache()
    }

    /// 检查 hosts 文件是否可读
    func isHostsFileReadable() -> Bool {
        fileManager.isReadableFile(atPath: hostsPath)
    }

    // MARK: - Private Methods

    /// 生成管理区域内容
    private func generateManagedSection(from groups: [HostGroup]) -> String {
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

            for entry in group.entries where entry.isEnabled {
                lines.append(entry.hostsLine)
            }

            lines.append(Marker.groupEnd(id: group.id, name: group.name))
            lines.append("")
        }

        // 区域尾部
        lines.append(Marker.sectionEnd)

        return lines.joined(separator: "\n")
    }

    /// 替换 hosts 文件中的管理区域
    private func replaceManagedSection(in content: String, with newSection: String) -> String {
        let lines = content.components(separatedBy: .newlines)
        var result: [String] = []
        var inManagedSection = false
        var foundSection = false

        for line in lines {
            if line.contains(Marker.sectionStart) {
                inManagedSection = true
                foundSection = true

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

    /// 使用管理员权限写入文件
    private func writeWithPrivilege(content: String, to path: String) throws {
        let tempFile = NSTemporaryDirectory() + "ienvs_hosts_\(UUID().uuidString)"
        try content.write(toFile: tempFile, atomically: true, encoding: .utf8)

        let escapedTempFile = tempFile.replacingOccurrences(of: "\"", with: "\\\"")
        let escapedPath = path.replacingOccurrences(of: "\"", with: "\\\"")

        let script = """
        do shell script "cp '\(escapedTempFile)' '\(escapedPath)' && rm -f '\(escapedTempFile)'" with administrator privileges
        """
        try executeAppleScript(script)

        // 清理临时文件（如果 AppleScript 失败，临时文件可能还在）
        try? fileManager.removeItem(atPath: tempFile)
    }

    /// 执行 AppleScript
    private func executeAppleScript(_ source: String) throws {
        var error: NSDictionary?
        guard let script = NSAppleScript(source: source) else {
            throw HostsFileError.scriptCreationFailed
        }

        script.executeAndReturnError(&error)

        if let error = error {
            let message = error[NSAppleScript.errorMessage] as? String ?? "Unknown error"
            throw HostsFileError.scriptExecutionFailed(message)
        }
    }

    /// 解析 hosts 文件中的一行
    private func parseHostsLine(_ line: String) -> HostEntry? {
        let trimmed = line.trimmingCharacters(in: .whitespaces)

        // 跳过空行和注释行
        guard !trimmed.isEmpty, !trimmed.hasPrefix("#") else {
            return nil
        }

        // 分离注释
        let commentSplit = trimmed.components(separatedBy: "#")
        let mainPart = commentSplit[0].trimmingCharacters(in: .whitespaces)
        let comment = commentSplit.count > 1
            ? commentSplit.dropFirst().joined(separator: "#").trimmingCharacters(in: .whitespaces)
            : ""

        // 分离 IP 和 hostname（使用 whitespaces 处理空格和制表符）
        let parts = mainPart.components(separatedBy: .whitespaces)
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }

        guard parts.count >= 2 else { return nil }

        let ip = parts[0]
        // 合并所有剩余部分作为主机名（处理多个主机名或包含空格的情况）
        let hostname = parts.dropFirst().joined(separator: " ")

        return HostEntry(
            ip: ip,
            hostname: hostname,
            comment: comment,
            isEnabled: true
        )
    }
}

// MARK: - Error Types
enum HostsFileError: LocalizedError {
    case scriptCreationFailed
    case scriptExecutionFailed(String)
    case fileNotFound
    case invalidLineNumber(Int)

    var errorDescription: String? {
        switch self {
        case .scriptCreationFailed:
            return "Failed to create AppleScript"
        case .scriptExecutionFailed(let message):
            return message
        case .fileNotFound:
            return "找不到 hosts 文件"
        case .invalidLineNumber(let line):
            return "无效的行号: \(line)"
        }
    }
}
