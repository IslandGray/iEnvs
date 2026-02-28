import Foundation

/// Hosts 导出数据格式
struct HostsExportData: Codable {
    let version: String
    let exportDate: Date
    let hostsGroups: [HostGroup]
}

final class HostsImportExportManager {
    // MARK: - Export Methods

    /// 导出为 JSON
    static func exportToJSON(groups: [HostGroup]) -> Data {
        let exportData = HostsExportData(
            version: "1.0",
            exportDate: Date(),
            hostsGroups: groups
        )

        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]

        do {
            return try encoder.encode(exportData)
        } catch {
            print("HostsImportExportManager.exportToJSON() error: \(error.localizedDescription)")
            return Data()
        }
    }

    /// 从 JSON 导入
    static func importFromJSON(data: Data) -> [HostGroup]? {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601

        do {
            let exportData = try decoder.decode(HostsExportData.self, from: data)

            guard exportData.version == "1.0" else {
                print("HostsImportExportManager: Incompatible version \(exportData.version)")
                return nil
            }

            return exportData.hostsGroups
        } catch {
            print("HostsImportExportManager.importFromJSON() error: \(error.localizedDescription)")
            return nil
        }
    }

    /// 导出为标准 hosts 格式文本
    static func exportToHostsFormat(groups: [HostGroup]) -> String {
        var lines: [String] = []

        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"

        lines.append("# iEnvs Hosts Export")
        lines.append("# Generated: \(dateFormatter.string(from: Date()))")
        lines.append("")

        for group in groups {
            lines.append("# === \(group.name) ===")
            if !group.description.isEmpty {
                lines.append("# \(group.description)")
            }

            for entry in group.entries {
                if entry.isEnabled {
                    lines.append(entry.hostsLine)
                } else {
                    // 禁用的条目以注释形式导出
                    lines.append("# [disabled] \(entry.hostsLine)")
                }
            }
            lines.append("")
        }

        return lines.joined(separator: "\n")
    }

    /// 从标准 hosts 格式文件导入
    static func importFromHostsFormat(content: String, groupName: String) -> HostGroup {
        let lines = content.components(separatedBy: .newlines)
        var entries: [HostEntry] = []

        for line in lines {
            let trimmed = line.trimmingCharacters(in: .whitespaces)

            // 跳过空行和注释行
            guard !trimmed.isEmpty, !trimmed.hasPrefix("#") else { continue }

            // 分离注释
            let commentSplit = trimmed.components(separatedBy: "#")
            let mainPart = commentSplit[0].trimmingCharacters(in: .whitespaces)
            let comment = commentSplit.count > 1
                ? commentSplit.dropFirst().joined(separator: "#").trimmingCharacters(in: .whitespaces)
                : ""

            // 分离 IP 和 hostname
            let parts = mainPart.split(separator: " ", omittingEmptySubsequences: true)
                .map { String($0).trimmingCharacters(in: .whitespaces) }

            guard parts.count >= 2 else { continue }

            let ip = parts[0]
            // 一个 IP 可能对应多个 hostname
            for i in 1..<parts.count {
                let hostname = parts[i]
                entries.append(HostEntry(
                    ip: ip,
                    hostname: hostname,
                    comment: i == 1 ? comment : "",
                    isEnabled: true
                ))
            }
        }

        return HostGroup(
            name: groupName,
            entries: entries
        )
    }
}
