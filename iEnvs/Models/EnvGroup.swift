import Foundation

struct EnvGroup: Identifiable, Codable, Equatable {
    var id: UUID = UUID()
    var name: String
    var description: String = ""
    var isEnabled: Bool = false
    var variables: [EnvVariable] = []
    var order: Int = 0
    var createdAt: Date = Date()
    var updatedAt: Date = Date()
}

extension EnvGroup {
    var variableCount: Int {
        variables.count
    }
}
