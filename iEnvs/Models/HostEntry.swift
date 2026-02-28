import Foundation

struct HostEntry: Identifiable, Codable, Equatable {
    var id: UUID = UUID()
    var ip: String
    var hostname: String
    var comment: String = ""
    var isEnabled: Bool = true
    var createdAt: Date = Date()
    var updatedAt: Date = Date()
}

extension HostEntry {
    var isValid: Bool {
        HostsValidators.validateIP(ip) && HostsValidators.validateHostname(hostname)
    }

    /// 生成 hosts 文件行
    var hostsLine: String {
        let commentPart = comment.isEmpty ? "" : " # \(comment)"
        return "\(ip) \(hostname)\(commentPart)"
    }
}
