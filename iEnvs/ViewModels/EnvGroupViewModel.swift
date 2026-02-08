import Foundation
import SwiftUI

@MainActor
final class EnvGroupViewModel: ObservableObject {
    // MARK: - Published Properties
    @Published var groups: [EnvGroup] = []
    @Published var selectedGroupId: UUID? = nil
    @Published var searchText: String = ""
    @Published var conflicts: [ConflictInfo] = []
    @Published var showNotification: Bool = false
    @Published var notificationMessage: String = ""

    // MARK: - Dependencies
    private let dataStore = DataStore.shared
    private let shellConfigManager = ShellConfigManager()
    private let conflictDetector = ConflictDetector()
    private let backupManager = BackupManager.shared

    // MARK: - Computed Properties
    var selectedGroup: EnvGroup? {
        guard let id = selectedGroupId else { return nil }
        return groups.first { $0.id == id }
    }

    var filteredGroups: [EnvGroup] {
        guard !searchText.isEmpty else { return groups }

        return groups.filter { group in
            group.name.localizedCaseInsensitiveContains(searchText) ||
            group.description.localizedCaseInsensitiveContains(searchText) ||
            group.variables.contains { variable in
                variable.key.localizedCaseInsensitiveContains(searchText) ||
                variable.value.localizedCaseInsensitiveContains(searchText)
            }
        }
    }

    // MARK: - Initialization
    init() {
        loadData()
    }

    // MARK: - Data Loading/Saving
    func loadData() {
        let appData = dataStore.load()
        groups = appData.groups.sorted { $0.order < $1.order }
        refreshConflicts()
    }

    func saveData() {
        var appData = dataStore.load()
        appData.groups = groups
        dataStore.save(appData)

        syncShellConfig()
        refreshConflicts()
    }

    // MARK: - Group Operations
    func addGroup(name: String, description: String) {
        let newGroup = EnvGroup(
            name: name,
            description: description,
            isEnabled: false,
            variables: [],
            order: groups.count,
            createdAt: Date(),
            updatedAt: Date()
        )

        groups.append(newGroup)
        saveData()

        notificationMessage = "已添加分组：\(name)"
        showNotification = true
    }

    func deleteGroup(id: UUID) {
        guard let index = groups.firstIndex(where: { $0.id == id }) else { return }
        let groupName = groups[index].name

        groups.remove(at: index)

        // 重新排序
        for (index, _) in groups.enumerated() {
            groups[index].order = index
        }

        saveData()

        notificationMessage = "已删除分组：\(groupName)"
        showNotification = true
    }

    func updateGroup(id: UUID, name: String, description: String) {
        guard let index = groups.firstIndex(where: { $0.id == id }) else { return }

        groups[index].name = name
        groups[index].description = description
        groups[index].updatedAt = Date()

        saveData()

        notificationMessage = "已更新分组：\(name)"
        showNotification = true
    }

    func moveGroup(from source: IndexSet, to destination: Int) {
        groups.move(fromOffsets: source, toOffset: destination)

        // 重新排序
        for (index, _) in groups.enumerated() {
            groups[index].order = index
        }

        saveData()
    }

    func toggleGroup(id: UUID) {
        guard let index = groups.firstIndex(where: { $0.id == id }) else { return }

        groups[index].isEnabled.toggle()
        groups[index].updatedAt = Date()

        let status = groups[index].isEnabled ? "启用" : "禁用"
        saveData()

        notificationMessage = "已\(status)分组：\(groups[index].name)"
        showNotification = true

        if groups[index].isEnabled {
            showSourceReminder()
        }
    }

    func duplicateGroup(id: UUID) {
        guard let index = groups.firstIndex(where: { $0.id == id }) else { return }

        var duplicatedGroup = groups[index]
        duplicatedGroup.id = UUID()
        duplicatedGroup.name = "\(duplicatedGroup.name) (副本)"
        duplicatedGroup.isEnabled = false
        duplicatedGroup.order = groups.count
        duplicatedGroup.createdAt = Date()
        duplicatedGroup.updatedAt = Date()

        // 复制变量并生成新 ID
        duplicatedGroup.variables = duplicatedGroup.variables.map { variable in
            var newVariable = variable
            newVariable.id = UUID()
            newVariable.createdAt = Date()
            newVariable.updatedAt = Date()
            return newVariable
        }

        groups.append(duplicatedGroup)
        saveData()

        notificationMessage = "已复制分组：\(duplicatedGroup.name)"
        showNotification = true
    }

    // MARK: - Variable Operations
    func addVariable(to groupId: UUID, key: String, value: String) {
        guard let index = groups.firstIndex(where: { $0.id == groupId }) else { return }

        let newVariable = EnvVariable(
            key: key,
            value: value,
            isSensitive: false,
            createdAt: Date(),
            updatedAt: Date()
        )

        groups[index].variables.append(newVariable)
        groups[index].updatedAt = Date()

        saveData()

        notificationMessage = "已添加变量：\(key)"
        showNotification = true
    }

    func deleteVariable(from groupId: UUID, variableId: UUID) {
        guard let groupIndex = groups.firstIndex(where: { $0.id == groupId }),
              let varIndex = groups[groupIndex].variables.firstIndex(where: { $0.id == variableId }) else {
            return
        }

        let key = groups[groupIndex].variables[varIndex].key
        groups[groupIndex].variables.remove(at: varIndex)
        groups[groupIndex].updatedAt = Date()

        saveData()

        notificationMessage = "已删除变量：\(key)"
        showNotification = true
    }

    func updateVariable(in groupId: UUID, variableId: UUID, key: String, value: String) {
        guard let groupIndex = groups.firstIndex(where: { $0.id == groupId }),
              let varIndex = groups[groupIndex].variables.firstIndex(where: { $0.id == variableId }) else {
            return
        }

        groups[groupIndex].variables[varIndex].key = key
        groups[groupIndex].variables[varIndex].value = value
        groups[groupIndex].variables[varIndex].updatedAt = Date()
        groups[groupIndex].updatedAt = Date()

        saveData()

        notificationMessage = "已更新变量：\(key)"
        showNotification = true
    }

    func toggleSensitive(in groupId: UUID, variableId: UUID) {
        guard let groupIndex = groups.firstIndex(where: { $0.id == groupId }),
              let varIndex = groups[groupIndex].variables.firstIndex(where: { $0.id == variableId }) else {
            return
        }

        groups[groupIndex].variables[varIndex].isSensitive.toggle()
        groups[groupIndex].variables[varIndex].updatedAt = Date()

        saveData()
    }

    // MARK: - Conflict Detection
    func refreshConflicts() {
        conflicts = conflictDetector.detectConflicts(in: groups)
    }

    func hasConflict(groupId: UUID) -> Bool {
        conflicts.contains { conflict in
            conflict.affectedGroupIDs.contains(groupId)
        }
    }

    func conflictsForVariable(key: String) -> ConflictInfo? {
        conflicts.first { $0.key == key }
    }

    // MARK: - Shell Sync
    private func syncShellConfig() {
        let appData = dataStore.load()
        let settings = appData.settings

        do {
            try shellConfigManager.syncToShellConfig(
                groups: groups,
                shellType: settings.shellType
            )
        } catch {
            notificationMessage = "同步 Shell 配置失败：\(error.localizedDescription)"
            showNotification = true
        }
    }

    private func showSourceReminder() {
        let appData = dataStore.load()
        let configPath = appData.settings.configFilePath

        notificationMessage = "配置已更新，请运行以下命令使其生效：\nsource \(configPath)"
        showNotification = true
    }

    // MARK: - Search
    func filteredVariables(for group: EnvGroup) -> [EnvVariable] {
        guard !searchText.isEmpty else { return group.variables }

        return group.variables.filter { variable in
            variable.key.localizedCaseInsensitiveContains(searchText) ||
            variable.value.localizedCaseInsensitiveContains(searchText)
        }
    }
}
