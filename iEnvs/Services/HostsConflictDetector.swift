import Foundation

final class HostsConflictDetector {
    /// 检测所有 Hosts 冲突（同一 hostname 映射到不同 IP）
    func detectConflicts(in groups: [HostGroup]) -> [HostsConflictInfo] {
        let enabledGroups = groups.filter { $0.isEnabled }
        var conflicts: [HostsConflictInfo] = []
        var hostnameToEntries: [String: [(group: HostGroup, entry: HostEntry)]] = [:]

        // 收集所有 hostname 及其所属分组
        for group in enabledGroups {
            for entry in group.entries where entry.isEnabled {
                hostnameToEntries[entry.hostname, default: []].append((group, entry))
            }
        }

        // 找出映射到不同 IP 的 hostname
        for (hostname, groupEntryPairs) in hostnameToEntries where groupEntryPairs.count > 1 {
            let uniqueIPs = Set(groupEntryPairs.map { $0.entry.ip })
            // 只有映射到不同 IP 时才算冲突
            guard uniqueIPs.count > 1 else { continue }

            let sortedPairs = groupEntryPairs.sorted { $0.group.order < $1.group.order }
            let effectivePair = sortedPairs.last!

            conflicts.append(HostsConflictInfo(
                hostname: hostname,
                affectedGroups: sortedPairs.map { $0.group },
                effectiveGroup: effectivePair.group,
                effectiveIP: effectivePair.entry.ip
            ))
        }

        return conflicts
    }

    /// 检查特定 hostname 在分组内是否重复
    func isDuplicateInGroup(_ hostname: String, in group: HostGroup, excluding entryID: UUID? = nil) -> Bool {
        group.entries.contains { entry in
            entry.hostname == hostname && entry.id != entryID
        }
    }
}

// MARK: - Supporting Types
struct HostsConflictInfo: Identifiable, Equatable {
    let id = UUID()
    let hostname: String
    let affectedGroups: [HostGroup]
    let effectiveGroup: HostGroup
    let effectiveIP: String

    var affectedGroupIDs: Set<UUID> {
        Set(affectedGroups.map { $0.id })
    }

    var localizedDescription: String {
        let separator = LocalizationManager.currentLanguage == .zh ? "、" : ", "
        let groupNames = affectedGroups.map { $0.name }.joined(separator: separator)
        return L10n.Hosts.conflictDescription(hostname: hostname, groupNames: groupNames)
    }

    static func == (lhs: HostsConflictInfo, rhs: HostsConflictInfo) -> Bool {
        lhs.hostname == rhs.hostname && lhs.affectedGroupIDs == rhs.affectedGroupIDs
    }
}
