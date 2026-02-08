import Foundation

final class ConflictDetector {
    /// 检测所有冲突
    func detectConflicts(in groups: [EnvGroup]) -> [ConflictInfo] {
        let enabledGroups = groups.filter { $0.isEnabled }
        var conflicts: [ConflictInfo] = []
        var keyToGroups: [String: [(group: EnvGroup, variable: EnvVariable)]] = [:]

        // 收集所有变量名及其所属分组
        for group in enabledGroups {
            for variable in group.variables {
                keyToGroups[variable.key, default: []].append((group, variable))
            }
        }

        // 找出重复的变量名
        for (key, groupVarPairs) in keyToGroups where groupVarPairs.count > 1 {
            let sortedPairs = groupVarPairs.sorted { $0.group.order < $1.group.order }
            let effectivePair = sortedPairs.last! // 最后一个分组生效

            conflicts.append(ConflictInfo(
                key: key,
                affectedGroups: sortedPairs.map { $0.group },
                effectiveGroup: effectivePair.group,
                effectiveValue: effectivePair.variable.value
            ))
        }

        return conflicts
    }

    /// 检查特定变量名在分组内是否重复
    func isDuplicateInGroup(_ key: String, in group: EnvGroup, excluding variableID: UUID? = nil) -> Bool {
        group.variables.contains { variable in
            variable.key == key && variable.id != variableID
        }
    }
}

// MARK: - Supporting Types
struct ConflictInfo: Identifiable, Equatable {
    let id = UUID()
    let key: String
    let affectedGroups: [EnvGroup]
    let effectiveGroup: EnvGroup
    let effectiveValue: String

    var affectedGroupIDs: Set<UUID> {
        Set(affectedGroups.map { $0.id })
    }

    var description: String {
        let groupNames = affectedGroups.map { $0.name }.joined(separator: "、")
        return "变量 \(key) 在以下分组中重复：\(groupNames)"
    }

    static func == (lhs: ConflictInfo, rhs: ConflictInfo) -> Bool {
        lhs.key == rhs.key && lhs.affectedGroupIDs == rhs.affectedGroupIDs
    }
}
