import Foundation

struct HostGroup: Identifiable, Codable, Equatable {
    var id: UUID = UUID()
    var name: String
    var description: String = ""
    var isEnabled: Bool = false
    var entries: [HostEntry] = []
    var order: Int = 0
    var createdAt: Date = Date()
    var updatedAt: Date = Date()
}

extension HostGroup {
    var entryCount: Int {
        entries.count
    }

    var enabledEntryCount: Int {
        entries.filter { $0.isEnabled }.count
    }
}
