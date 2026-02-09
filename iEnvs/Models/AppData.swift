import Foundation

struct AppData: Codable {
    var version: String
    var groups: [EnvGroup]
    var settings: AppSettings
    var lastSavedAt: Date

    init(
        version: String = "1.0",
        groups: [EnvGroup] = [],
        settings: AppSettings = AppSettings(),
        lastSavedAt: Date = Date()
    ) {
        self.version = version
        self.groups = groups
        self.settings = settings
        self.lastSavedAt = lastSavedAt
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
