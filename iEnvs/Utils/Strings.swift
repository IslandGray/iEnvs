import Foundation

enum L10n {
    private static func t(_ table: [AppLanguage: String]) -> String {
        table[LocalizationManager.currentLanguage] ?? table[.en] ?? ""
    }

    // MARK: - General

    enum General {
        static var cancel: String { t([.zh: "取消", .en: "Cancel"]) }
        static var confirm: String { t([.zh: "确认", .en: "Confirm"]) }
        static var delete: String { t([.zh: "删除", .en: "Delete"]) }
        static var edit: String { t([.zh: "编辑", .en: "Edit"]) }
        static var close: String { t([.zh: "关闭", .en: "Close"]) }
        static var ok: String { t([.zh: "确定", .en: "OK"]) }
        static var refresh: String { t([.zh: "刷新", .en: "Refresh"]) }
        static var rename: String { t([.zh: "重命名", .en: "Rename"]) }
        static var duplicate: String { t([.zh: "复制", .en: "Duplicate"]) }
        static var search: String { t([.zh: "搜索", .en: "Search"]) }
    }

    // MARK: - Sidebar

    enum Sidebar {
        static var groups: String { t([.zh: "分组", .en: "Groups"]) }
        static var addGroup: String { t([.zh: "添加分组", .en: "Add Group"]) }
        static var deleteGroup: String { t([.zh: "删除分组", .en: "Delete Group"]) }
        static var confirmDelete: String { t([.zh: "确认删除", .en: "Confirm Delete"]) }
        static func confirmDeleteMessage(_ name: String) -> String {
            t([.zh: "确定要删除分组「\(name)」吗？此操作不可撤销。",
               .en: "Are you sure you want to delete group \"\(name)\"? This action cannot be undone."])
        }
    }

    // MARK: - Detail

    enum Detail {
        static var addVariable: String { t([.zh: "添加变量", .en: "Add Variable"]) }
        static var addVariableHelp: String { t([.zh: "添加新的环境变量", .en: "Add a new environment variable"]) }
        static var deleteHelp: String { t([.zh: "删除选中的变量", .en: "Delete selected variables"]) }
        static var filterPlaceholder: String { t([.zh: "过滤变量...", .en: "Filter variables..."]) }
        static var columnKey: String { t([.zh: "变量名", .en: "Variable"]) }
        static var columnValue: String { t([.zh: "变量值", .en: "Value"]) }
        static var copyValue: String { t([.zh: "复制值", .en: "Copy Value"]) }
        static var markNormal: String { t([.zh: "标记为普通", .en: "Mark as Normal"]) }
        static var markSensitive: String { t([.zh: "标记为敏感", .en: "Mark as Sensitive"]) }
        static var showSensitive: String { t([.zh: "显示敏感值", .en: "Show sensitive value"]) }
        static var hideSensitive: String { t([.zh: "隐藏敏感值", .en: "Hide sensitive value"]) }
        static func variableCount(_ count: Int) -> String {
            t([.zh: "\(count) 个变量", .en: "\(count) variables"])
        }
        static var conflictWarning: String { t([.zh: "此分组存在变量冲突", .en: "This group has variable conflicts"]) }
    }

    // MARK: - Empty State

    enum EmptyState {
        static var noVariables: String { t([.zh: "此分组暂无环境变量", .en: "No environment variables in this group"]) }
        static var addVariableHint: String { t([.zh: "点击 + 按钮添加环境变量", .en: "Click the + button to add environment variables"]) }
    }

    // MARK: - Add Group

    enum AddGroup {
        static var title: String { t([.zh: "添加新分组", .en: "Add New Group"]) }
        static var groupName: String { t([.zh: "分组名称", .en: "Group Name"]) }
        static var groupNamePlaceholder: String { t([.zh: "例如：前端开发", .en: "e.g. Frontend Dev"]) }
        static var descriptionLabel: String { t([.zh: "描述（可选）", .en: "Description (optional)"]) }
        static var descriptionPlaceholder: String { t([.zh: "例如：Node.js 项目环境变量", .en: "e.g. Node.js project env vars"]) }
        static var nameTooLong: String { t([.zh: "分组名称不能超过 100 个字符", .en: "Group name cannot exceed 100 characters"]) }
        static var nameExists: String { t([.zh: "该分组名称已存在", .en: "This group name already exists"]) }
    }

    // MARK: - Add Variable

    enum AddVariable {
        static var title: String { t([.zh: "添加环境变量", .en: "Add Environment Variable"]) }
        static var variableName: String { t([.zh: "变量名", .en: "Variable Name"]) }
        static var variableNamePlaceholder: String { t([.zh: "例如: NODE_ENV", .en: "e.g. NODE_ENV"]) }
        static var variableValue: String { t([.zh: "变量值", .en: "Variable Value"]) }
        static var variableValuePlaceholder: String { t([.zh: "例如: production", .en: "e.g. production"]) }
        static var sensitiveInfo: String { t([.zh: "敏感信息", .en: "Sensitive"]) }
        static var sensitiveHelp: String { t([.zh: "敏感信息将在列表中隐藏显示", .en: "Sensitive values will be hidden in the list"]) }
        static var nameValid: String { t([.zh: "变量名有效", .en: "Valid variable name"]) }
        static var nameExists: String { t([.zh: "该变量名已存在", .en: "This variable name already exists"]) }
        static var nameInvalid: String { t([.zh: "只能包含字母、数字和下划线，且必须以字母或下划线开头", .en: "Must contain only letters, digits and underscores, starting with a letter or underscore"]) }
        static var nameFormatError: String { t([.zh: "变量名格式不正确", .en: "Invalid variable name format"]) }
        static var batchImport: String { t([.zh: "批量导入", .en: "Batch Import"]) }
        static var batchImportHelp: String { t([.zh: "粘贴多行 KEY=VALUE 格式", .en: "Paste multiple KEY=VALUE lines"]) }
        static var batchImportTitle: String { t([.zh: "批量导入", .en: "Batch Import"]) }
        static var batchImportFormat: String { t([.zh: "每行一个变量，格式: KEY=VALUE", .en: "One variable per line, format: KEY=VALUE"]) }
        static var importButton: String { t([.zh: "导入", .en: "Import"]) }
        static var addButton: String { t([.zh: "添加", .en: "Add"]) }
        static func formatError(_ line: String) -> String {
            t([.zh: "格式错误: \(line)", .en: "Format error: \(line)"])
        }
        static func invalidName(_ key: String) -> String {
            t([.zh: "无效的变量名: \(key)", .en: "Invalid variable name: \(key)"])
        }
        static func variableExists(_ key: String) -> String {
            t([.zh: "变量已存在: \(key)", .en: "Variable already exists: \(key)"])
        }
        static func batchResult(imported: Int, errors: [String]) -> String {
            t([.zh: "成功导入 \(imported) 个变量\n错误: \(errors.joined(separator: "\n"))",
               .en: "Successfully imported \(imported) variables\nErrors: \(errors.joined(separator: "\n"))"])
        }
    }

    // MARK: - Settings

    enum Settings {
        static var general: String { t([.zh: "通用", .en: "General"]) }
        static var shell: String { "Shell" }
        static var backup: String { t([.zh: "备份", .en: "Backup"]) }
        static var preferences: String { t([.zh: "偏好设置", .en: "Preferences"]) }

        // Theme
        static var appearance: String { t([.zh: "外观", .en: "Appearance"]) }
        static var theme: String { t([.zh: "主题", .en: "Theme"]) }
        static var themeAuto: String { t([.zh: "自动", .en: "Auto"]) }
        static var themeLight: String { t([.zh: "浅色", .en: "Light"]) }
        static var themeDark: String { t([.zh: "深色", .en: "Dark"]) }
        static var themeNote: String { t([.zh: "注意: macOS 应用主题跟随系统设置", .en: "Note: macOS app theme follows system settings"]) }

        // Language
        static var language: String { t([.zh: "语言 / Language", .en: "Language"]) }
        static var languagePicker: String { t([.zh: "界面语言", .en: "Interface Language"]) }

        // Conflict Detection
        static var conflictDetection: String { t([.zh: "冲突检测", .en: "Conflict Detection"]) }
        static var enableConflictDetection: String { t([.zh: "启用冲突检测", .en: "Enable conflict detection"]) }
        static var conflictDetectionDesc: String { t([.zh: "检测跨分组的变量名冲突并显示警告", .en: "Detect variable name conflicts across groups and show warnings"]) }

        // Export
        static var exportSettings: String { t([.zh: "导出设置", .en: "Export Settings"]) }
        static var exportIncludeDisabled: String { t([.zh: "导出时包含禁用的分组", .en: "Include disabled groups when exporting"]) }
        static var exportIncludeDisabledDesc: String { t([.zh: "导出 JSON 时是否包含未启用的分组", .en: "Whether to include disabled groups when exporting JSON"]) }

        // Shell
        static var detectedShell: String { t([.zh: "当前检测到的 Shell", .en: "Detected Shell"]) }
        static var detected: String { t([.zh: "已检测", .en: "Detected"]) }
        static var shellType: String { t([.zh: "Shell 类型", .en: "Shell Type"]) }
        static var selectShell: String { t([.zh: "选择 Shell", .en: "Select Shell"]) }
        static var shellTypeChangeNote: String { t([.zh: "更改 Shell 类型将自动更新配置文件路径", .en: "Changing shell type will automatically update the config file path"]) }
        static var configFilePath: String { t([.zh: "配置文件路径", .en: "Config File Path"]) }
        static var configFilePathPlaceholder: String { t([.zh: "配置文件路径", .en: "Config file path"]) }
        static var showInFinder: String { t([.zh: "在 Finder 中显示", .en: "Show in Finder"]) }
        static var configFileNote: String { t([.zh: "配置文件将在此位置写入环境变量", .en: "Environment variables will be written to this config file"]) }
        static var autoDetectShell: String { t([.zh: "自动检测 Shell", .en: "Auto Detect Shell"]) }
        static var autoDetectNote: String { t([.zh: "重新检测系统默认 Shell 并更新配置", .en: "Re-detect system default shell and update configuration"]) }

        // Backup
        static var autoBackup: String { t([.zh: "自动备份", .en: "Auto Backup"]) }
        static var autoBackupDesc: String { t([.zh: "在修改配置文件前自动创建备份", .en: "Automatically create backups before modifying config files"]) }
        static var maxBackupCount: String { t([.zh: "最大备份数量", .en: "Maximum Backup Count"]) }
        static var keepRecent: String { t([.zh: "保留最近", .en: "Keep recent"]) }
        static var backupsUnit: String { t([.zh: "个备份", .en: "backups"]) }
        static var autoDeleteNote: String { t([.zh: "超过此数量的旧备份将被自动删除", .en: "Old backups exceeding this count will be automatically deleted"]) }
        static var backupList: String { t([.zh: "备份列表", .en: "Backup List"]) }
        static var noBackups: String { t([.zh: "暂无备份", .en: "No backups"]) }
        static var restoreBackup: String { t([.zh: "恢复备份", .en: "Restore Backup"]) }
        static var deleteBackup: String { t([.zh: "删除备份", .en: "Delete Backup"]) }
        static func backupCount(_ count: Int) -> String {
            t([.zh: "\(count) 个备份", .en: "\(count) backups"])
        }
        static var deleteBackupTitle: String { t([.zh: "删除备份", .en: "Delete Backup"]) }
        static var deleteBackupConfirm: String { t([.zh: "确定要删除选中的备份吗？此操作无法撤销。", .en: "Are you sure you want to delete the selected backup? This action cannot be undone."]) }
    }

    // MARK: - Export/Import

    enum Export {
        static var title: String { t([.zh: "导入/导出", .en: "Import/Export"]) }
        static var exportTitle: String { t([.zh: "导出", .en: "Export"]) }
        static var exportDesc: String { t([.zh: "将环境变量分组导出为 JSON 文件", .en: "Export environment variable groups to a JSON file"]) }
        static var includeDisabled: String { t([.zh: "包含已禁用的分组", .en: "Include disabled groups"]) }
        static var exportJSON: String { t([.zh: "导出为 JSON", .en: "Export as JSON"]) }
        static var importTitle: String { t([.zh: "导入", .en: "Import"]) }
        static var importDesc: String { t([.zh: "从 JSON 文件导入环境变量分组", .en: "Import environment variable groups from a JSON file"]) }
        static var importRules: String { t([.zh: "导入时的处理规则:", .en: "Import rules:"]) }
        static var importRule1: String { t([.zh: "如果分组名已存在，将提示选择操作", .en: "If a group name already exists, you will be prompted to choose an action"]) }
        static var importRule2: String { t([.zh: "导入的分组默认为禁用状态", .en: "Imported groups are disabled by default"]) }
        static var importRule3: String { t([.zh: "将保留原有分组的顺序", .en: "Original group order will be preserved"]) }
        static var importJSON: String { t([.zh: "从 JSON 导入", .en: "Import from JSON"]) }
        static var operationResult: String { t([.zh: "操作结果", .en: "Result"]) }
        static var exportDialogTitle: String { t([.zh: "导出环境变量", .en: "Export Environment Variables"]) }
        static var exportDialogMessage: String { t([.zh: "选择导出文件的保存位置", .en: "Choose where to save the export file"]) }
        static var importDialogTitle: String { t([.zh: "导入环境变量", .en: "Import Environment Variables"]) }
        static var importDialogMessage: String { t([.zh: "选择要导入的 JSON 文件", .en: "Select the JSON file to import"]) }
        static func exportSuccess(count: Int, path: String) -> String {
            t([.zh: "成功导出 \(count) 个分组到:\n\(path)",
               .en: "Successfully exported \(count) groups to:\n\(path)"])
        }
        static func exportFailed(_ error: String) -> String {
            t([.zh: "导出失败:\n\(error)", .en: "Export failed:\n\(error)"])
        }
        static func importSuccess(count: Int) -> String {
            t([.zh: "导入完成:\n成功导入 \(count) 个分组",
               .en: "Import complete:\nSuccessfully imported \(count) groups"])
        }
        static func importSkipped(_ count: Int) -> String {
            t([.zh: "跳过 \(count) 个分组", .en: "Skipped \(count) groups"])
        }
        static func importFailed(_ error: String) -> String {
            t([.zh: "导入失败:\n\(error)", .en: "Import failed:\n\(error)"])
        }
        static var conflictTitle: String { t([.zh: "分组名称冲突", .en: "Group Name Conflict"]) }
        static func conflictMessage(_ name: String) -> String {
            t([.zh: "已存在名为「\(name)」的分组，请选择操作：",
               .en: "A group named \"\(name)\" already exists. Choose an action:"])
        }
        static var skip: String { t([.zh: "跳过", .en: "Skip"]) }
        static var overwrite: String { t([.zh: "覆盖", .en: "Overwrite"]) }
        static func importSuffix(_ baseName: String) -> String {
            t([.zh: "\(baseName)-导入", .en: "\(baseName)-imported"])
        }
        static func importSuffixN(_ baseName: String, _ n: Int) -> String {
            t([.zh: "\(baseName)-导入\(n)", .en: "\(baseName)-imported\(n)"])
        }
    }

    // MARK: - Status Bar

    enum StatusBar {
        static var tooltip: String { t([.zh: "iEnvs - 环境变量管理", .en: "iEnvs - Environment Variable Manager"]) }
        static var noGroups: String { t([.zh: "暂无分组", .en: "No groups"]) }
        static func groupInfo(_ name: String, _ count: Int) -> String {
            t([.zh: "\(name) (\(count)个变量)", .en: "\(name) (\(count) vars)"])
        }
        static var syncToShell: String { t([.zh: "同步到 Shell 配置", .en: "Sync to Shell Config"]) }
        static var openMainWindow: String { t([.zh: "打开主窗口", .en: "Open Main Window"]) }
        static var preferences: String { t([.zh: "偏好设置...", .en: "Preferences..."]) }
        static var quit: String { t([.zh: "退出 iEnvs", .en: "Quit iEnvs"]) }
    }

    // MARK: - Notifications

    enum Notification {
        static func groupAdded(_ name: String) -> String {
            t([.zh: "已添加分组：\(name)", .en: "Group added: \(name)"])
        }
        static func groupDeleted(_ name: String) -> String {
            t([.zh: "已删除分组：\(name)", .en: "Group deleted: \(name)"])
        }
        static func groupUpdated(_ name: String) -> String {
            t([.zh: "已更新分组：\(name)", .en: "Group updated: \(name)"])
        }
        static func groupToggled(enabled: Bool, name: String) -> String {
            let status = enabled
                ? t([.zh: "启用", .en: "enabled"])
                : t([.zh: "禁用", .en: "disabled"])
            return t([.zh: "已\(status)分组：\(name)", .en: "Group \(status): \(name)"])
        }
        static func groupDuplicated(_ name: String) -> String {
            t([.zh: "已复制分组：\(name)", .en: "Group duplicated: \(name)"])
        }
        static func variableAdded(_ key: String) -> String {
            t([.zh: "已添加变量：\(key)", .en: "Variable added: \(key)"])
        }
        static func variableDeleted(_ key: String) -> String {
            t([.zh: "已删除变量：\(key)", .en: "Variable deleted: \(key)"])
        }
        static func variableUpdated(_ key: String) -> String {
            t([.zh: "已更新变量：\(key)", .en: "Variable updated: \(key)"])
        }
        static func shellSyncFailed(_ error: String) -> String {
            t([.zh: "同步 Shell 配置失败：\(error)", .en: "Failed to sync shell config: \(error)"])
        }
        static func sourceReminder(_ path: String) -> String {
            t([.zh: "配置已更新，请运行以下命令使其生效：\nsource \(path)",
               .en: "Config updated. Run the following command to apply:\nsource \(path)"])
        }
        static func duplicateSuffix(_ name: String) -> String {
            t([.zh: "\(name) (副本)", .en: "\(name) (Copy)"])
        }
    }

    // MARK: - Conflict

    enum Conflict {
        static func description(key: String, groupNames: String) -> String {
            t([.zh: "变量 \(key) 在以下分组中重复：\(groupNames)",
               .en: "Variable \(key) is duplicated in groups: \(groupNames)"])
        }
    }

    // MARK: - Main View

    enum MainView {
        static var searchPrompt: String { t([.zh: "搜索分组或变量", .en: "Search groups or variables"]) }
        static var exportImport: String { t([.zh: "导入/导出", .en: "Import/Export"]) }
    }

    // MARK: - App Data

    enum AppData {
        static var sampleGroupName: String { t([.zh: "示例分组", .en: "Sample Group"]) }
        static var sampleGroupDesc: String { t([.zh: "这是一个示例分组，你可以删除它", .en: "This is a sample group, you can delete it"]) }
    }
}
