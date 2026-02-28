import Foundation

enum HostsValidators {
    /// 验证 IPv4 地址
    static func validateIPv4(_ ip: String) -> Bool {
        let parts = ip.split(separator: ".", omittingEmptySubsequences: false)
        guard parts.count == 4 else { return false }
        return parts.allSatisfy { part in
            guard let num = Int(part), num >= 0, num <= 255 else { return false }
            // 禁止前导零（除了 "0" 本身）
            return String(num) == String(part)
        }
    }

    /// 验证 IPv6 地址
    static func validateIPv6(_ ip: String) -> Bool {
        // 支持完整格式和压缩格式（::）
        let pattern = "^([0-9a-fA-F]{1,4}:){7}[0-9a-fA-F]{1,4}$|^(([0-9a-fA-F]{1,4}:)*[0-9a-fA-F]{1,4})?::(([0-9a-fA-F]{1,4}:)*[0-9a-fA-F]{1,4})?$"
        guard let regex = try? NSRegularExpression(pattern: pattern) else { return false }
        let range = NSRange(ip.startIndex..<ip.endIndex, in: ip)
        return regex.firstMatch(in: ip, range: range) != nil
    }

    /// 验证 IP 地址（IPv4 或 IPv6）
    static func validateIP(_ ip: String) -> Bool {
        validateIPv4(ip) || validateIPv6(ip)
    }

    /// 验证主机名 (RFC 1123)
    static func validateHostname(_ hostname: String) -> Bool {
        guard !hostname.isEmpty, hostname.count <= 253 else { return false }
        let pattern = "^([a-zA-Z0-9]([a-zA-Z0-9\\-]{0,61}[a-zA-Z0-9])?\\.)*[a-zA-Z0-9]([a-zA-Z0-9\\-]{0,61}[a-zA-Z0-9])?$"
        guard let regex = try? NSRegularExpression(pattern: pattern) else { return false }
        let range = NSRange(hostname.startIndex..<hostname.endIndex, in: hostname)
        return regex.firstMatch(in: hostname, range: range) != nil
    }
}
