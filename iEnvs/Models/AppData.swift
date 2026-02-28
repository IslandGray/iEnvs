import Foundation

struct AppData: Codable {
    var version: String
    var groups: [EnvGroup]
    var hostsGroups: [HostGroup]
    var settings: AppSettings
    var lastSavedAt: Date

    init(
        version: String = "1.0",
        groups: [EnvGroup] = [],
        hostsGroups: [HostGroup] = [],
        settings: AppSettings = AppSettings(),
        lastSavedAt: Date = Date()
    ) {
        self.version = version
        self.groups = groups
        self.hostsGroups = hostsGroups
        self.settings = settings
        self.lastSavedAt = lastSavedAt
    }

    // 向后兼容：旧版本数据无 hostsGroups 字段
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        version = try container.decode(String.self, forKey: .version)
        groups = try container.decode([EnvGroup].self, forKey: .groups)
        hostsGroups = try container.decodeIfPresent([HostGroup].self, forKey: .hostsGroups) ?? []
        settings = try container.decode(AppSettings.self, forKey: .settings)
        lastSavedAt = try container.decode(Date.self, forKey: .lastSavedAt)
    }
}

extension AppData {
    static var empty: AppData {
        AppData(
            groups: [],
            settings: AppSettings()
        )
    }

    static var `default`: AppData {
        AppData(
            groups: [
                EnvGroup(
                    name: "示例分组 / Sample Group",
                    description: "这是一个示例分组，你可以删除它 / This is a sample group, you can delete it",
                    isEnabled: false,
                    variables: [
                        EnvVariable(key: "EXAMPLE_VAR", value: "example_value")
                    ],
                    order: 0
                )
            ]
        )
    }
}
