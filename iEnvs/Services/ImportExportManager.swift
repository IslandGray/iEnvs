import Foundation

/// 导出数据格式
struct ExportData: Codable {
    let version: String
    let exportDate: Date
    let groups: [EnvGroup]
}

final class ImportExportManager {
    // MARK: - Export Methods

    /// 导出为 JSON
    static func exportToJSON(groups: [EnvGroup]) -> Data {
        let exportData = ExportData(
            version: "1.0",
            exportDate: Date(),
            groups: groups
        )

        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]

        do {
            return try encoder.encode(exportData)
        } catch {
            print("ImportExportManager.exportToJSON() error: \(error.localizedDescription)")
            return Data()
        }
    }

    /// 从 JSON 导入
    static func importFromJSON(data: Data) -> [EnvGroup]? {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601

        do {
            let exportData = try decoder.decode(ExportData.self, from: data)

            // 版本兼容性检查
            guard exportData.version == "1.0" else {
                print("ImportExportManager: Incompatible version \(exportData.version)")
                return nil
            }

            return exportData.groups
        } catch {
            print("ImportExportManager.importFromJSON() error: \(error.localizedDescription)")
            return nil
        }
    }

    /// 导出为 Shell 脚本
    static func exportToShellScript(group: EnvGroup) -> String {
        var lines: [String] = []

        // 头部
        lines.append("#!/bin/bash")
        lines.append("# iEnvs Export: \(group.name)")
        if !group.description.isEmpty {
            lines.append("# Description: \(group.description)")
        }

        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        lines.append("# Generated: \(dateFormatter.string(from: Date()))")
        lines.append("")

        // Export 语句
        for variable in group.variables {
            let exportLine = generateExportLine(key: variable.key, value: variable.value)
            lines.append(exportLine)
        }

        return lines.joined(separator: "\n")
    }

    // MARK: - Private Methods

    /// 生成 export 语句
    private static func generateExportLine(key: String, value: String) -> String {
        // 转义值中的特殊字符
        let escapedValue = value
            .replacingOccurrences(of: "\\", with: "\\\\")
            .replacingOccurrences(of: "\"", with: "\\\"")
            .replacingOccurrences(of: "$", with: "\\$")
            .replacingOccurrences(of: "`", with: "\\`")

        return "export \(key)=\"\(escapedValue)\""
    }
}
