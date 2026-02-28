import Foundation
import SwiftUI

@MainActor
final class HostsGroupViewModel: ObservableObject {
    // MARK: - Published Properties
    @Published var hostsGroups: [HostGroup] = []
    @Published var selectedHostsGroupId: UUID? = nil
    @Published var hostsSearchText: String = ""
    @Published var hostsConflicts: [HostsConflictInfo] = []
    @Published var showNotification: Bool = false
    @Published var notificationMessage: String = ""

    // MARK: - Dependencies
    private let dataStore = DataStore.shared
    private let hostsFileManager = HostsFileManager()
    private let conflictDetector = HostsConflictDetector()

    // MARK: - Computed Properties
    var selectedGroup: HostGroup? {
        guard let id = selectedHostsGroupId else { return nil }
        return hostsGroups.first { $0.id == id }
    }

    var filteredGroups: [HostGroup] {
        guard !hostsSearchText.isEmpty else { return hostsGroups }

        return hostsGroups.filter { group in
            group.name.localizedCaseInsensitiveContains(hostsSearchText) ||
            group.description.localizedCaseInsensitiveContains(hostsSearchText) ||
            group.entries.contains { entry in
                entry.ip.localizedCaseInsensitiveContains(hostsSearchText) ||
                entry.hostname.localizedCaseInsensitiveContains(hostsSearchText) ||
                entry.comment.localizedCaseInsensitiveContains(hostsSearchText)
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
        hostsGroups = appData.hostsGroups.sorted { $0.order < $1.order }
        refreshHostsConflicts()
    }

    func saveData() {
        var appData = dataStore.load()
        appData.hostsGroups = hostsGroups
        dataStore.save(appData)

        refreshHostsConflicts()
    }

    // MARK: - Group Operations
    func addHostsGroup(name: String, description: String) {
        let newGroup = HostGroup(
            name: name,
            description: description,
            isEnabled: false,
            entries: [],
            order: hostsGroups.count,
            createdAt: Date(),
            updatedAt: Date()
        )

        hostsGroups.append(newGroup)
        saveData()

        notificationMessage = L10n.Hosts.groupAdded(name)
        showNotification = true
    }

    func deleteHostsGroup(id: UUID) {
        guard let index = hostsGroups.firstIndex(where: { $0.id == id }) else { return }
        let groupName = hostsGroups[index].name
        let wasEnabled = hostsGroups[index].isEnabled

        hostsGroups.remove(at: index)

        for (index, _) in hostsGroups.enumerated() {
            hostsGroups[index].order = index
        }

        saveData()

        if wasEnabled {
            syncHostsFile()
        }

        notificationMessage = L10n.Hosts.groupDeleted(groupName)
        showNotification = true
    }

    func updateHostsGroup(id: UUID, name: String, description: String) {
        guard let index = hostsGroups.firstIndex(where: { $0.id == id }) else { return }

        hostsGroups[index].name = name
        hostsGroups[index].description = description
        hostsGroups[index].updatedAt = Date()

        saveData()

        if hostsGroups[index].isEnabled {
            syncHostsFile()
        }

        notificationMessage = L10n.Hosts.groupUpdated(name)
        showNotification = true
    }

    func moveHostsGroup(from source: IndexSet, to destination: Int) {
        hostsGroups.move(fromOffsets: source, toOffset: destination)

        for (index, _) in hostsGroups.enumerated() {
            hostsGroups[index].order = index
        }

        saveData()
        syncHostsFile()
    }

    func toggleHostsGroup(id: UUID) {
        guard let index = hostsGroups.firstIndex(where: { $0.id == id }) else { return }

        hostsGroups[index].isEnabled.toggle()
        hostsGroups[index].updatedAt = Date()

        saveData()
        syncHostsFile()

        notificationMessage = L10n.Hosts.groupToggled(enabled: hostsGroups[index].isEnabled, name: hostsGroups[index].name)
        showNotification = true
    }

    func duplicateHostsGroup(id: UUID) {
        guard let index = hostsGroups.firstIndex(where: { $0.id == id }) else { return }

        var duplicatedGroup = hostsGroups[index]
        duplicatedGroup.id = UUID()
        duplicatedGroup.name = L10n.Notification.duplicateSuffix(duplicatedGroup.name)
        duplicatedGroup.isEnabled = false
        duplicatedGroup.order = hostsGroups.count
        duplicatedGroup.createdAt = Date()
        duplicatedGroup.updatedAt = Date()

        duplicatedGroup.entries = duplicatedGroup.entries.map { entry in
            var newEntry = entry
            newEntry.id = UUID()
            newEntry.createdAt = Date()
            newEntry.updatedAt = Date()
            return newEntry
        }

        hostsGroups.append(duplicatedGroup)
        saveData()

        notificationMessage = L10n.Hosts.groupDuplicated(duplicatedGroup.name)
        showNotification = true
    }

    // MARK: - Entry Operations
    func addHostEntry(to groupId: UUID, ip: String, hostname: String, comment: String = "") {
        guard let index = hostsGroups.firstIndex(where: { $0.id == groupId }) else { return }

        let newEntry = HostEntry(
            ip: ip,
            hostname: hostname,
            comment: comment,
            isEnabled: true,
            createdAt: Date(),
            updatedAt: Date()
        )

        hostsGroups[index].entries.append(newEntry)
        hostsGroups[index].updatedAt = Date()

        saveData()

        if hostsGroups[index].isEnabled {
            syncHostsFile()
        }

        notificationMessage = L10n.Hosts.entryAdded(hostname)
        showNotification = true
    }

    func deleteHostEntry(from groupId: UUID, entryId: UUID) {
        guard let groupIndex = hostsGroups.firstIndex(where: { $0.id == groupId }),
              let entryIndex = hostsGroups[groupIndex].entries.firstIndex(where: { $0.id == entryId }) else {
            return
        }

        let hostname = hostsGroups[groupIndex].entries[entryIndex].hostname
        hostsGroups[groupIndex].entries.remove(at: entryIndex)
        hostsGroups[groupIndex].updatedAt = Date()

        saveData()

        if hostsGroups[groupIndex].isEnabled {
            syncHostsFile()
        }

        notificationMessage = L10n.Hosts.entryDeleted(hostname)
        showNotification = true
    }

    func updateHostEntry(in groupId: UUID, entryId: UUID, ip: String, hostname: String, comment: String) {
        guard let groupIndex = hostsGroups.firstIndex(where: { $0.id == groupId }),
              let entryIndex = hostsGroups[groupIndex].entries.firstIndex(where: { $0.id == entryId }) else {
            return
        }

        hostsGroups[groupIndex].entries[entryIndex].ip = ip
        hostsGroups[groupIndex].entries[entryIndex].hostname = hostname
        hostsGroups[groupIndex].entries[entryIndex].comment = comment
        hostsGroups[groupIndex].entries[entryIndex].updatedAt = Date()
        hostsGroups[groupIndex].updatedAt = Date()

        saveData()

        if hostsGroups[groupIndex].isEnabled {
            syncHostsFile()
        }

        notificationMessage = L10n.Hosts.entryUpdated(hostname)
        showNotification = true
    }

    func toggleHostEntry(in groupId: UUID, entryId: UUID) {
        guard let groupIndex = hostsGroups.firstIndex(where: { $0.id == groupId }),
              let entryIndex = hostsGroups[groupIndex].entries.firstIndex(where: { $0.id == entryId }) else {
            return
        }

        hostsGroups[groupIndex].entries[entryIndex].isEnabled.toggle()
        hostsGroups[groupIndex].entries[entryIndex].updatedAt = Date()

        saveData()

        if hostsGroups[groupIndex].isEnabled {
            syncHostsFile()
        }
    }

    // MARK: - Conflict Detection
    func refreshHostsConflicts() {
        hostsConflicts = conflictDetector.detectConflicts(in: hostsGroups)
    }

    func hasConflict(groupId: UUID) -> Bool {
        hostsConflicts.contains { conflict in
            conflict.affectedGroupIDs.contains(groupId)
        }
    }

    // MARK: - Hosts File Sync
    func syncHostsFile() {
        do {
            try hostsFileManager.syncToHostsFile(groups: hostsGroups)
            let enabledCount = hostsGroups.filter { $0.isEnabled }.count
            notificationMessage = L10n.Hosts.syncSuccess(enabledCount)
            showNotification = true
        } catch {
            notificationMessage = L10n.Hosts.syncFailed(error.localizedDescription)
            showNotification = true
        }
    }

    func flushDNS() {
        do {
            try hostsFileManager.flushDNSCache()
            notificationMessage = L10n.Hosts.flushDNSSuccess
            showNotification = true
        } catch {
            notificationMessage = L10n.Hosts.flushDNSFailed
            showNotification = true
        }
    }

    // MARK: - Search
    func filteredEntries(for group: HostGroup) -> [HostEntry] {
        guard !hostsSearchText.isEmpty else { return group.entries }

        return group.entries.filter { entry in
            entry.ip.localizedCaseInsensitiveContains(hostsSearchText) ||
            entry.hostname.localizedCaseInsensitiveContains(hostsSearchText) ||
            entry.comment.localizedCaseInsensitiveContains(hostsSearchText)
        }
    }

    // MARK: - Import
    func importGroups(_ groups: [HostGroup]) {
        for var group in groups {
            group.id = UUID()
            group.isEnabled = false
            group.order = hostsGroups.count

            group.entries = group.entries.map { entry in
                var newEntry = entry
                newEntry.id = UUID()
                return newEntry
            }

            hostsGroups.append(group)
        }

        saveData()
    }
}
