import Foundation

struct EnvVariable: Identifiable, Codable, Equatable {
    var id: UUID = UUID()
    var key: String
    var value: String
    var isSensitive: Bool = false
    var createdAt: Date = Date()
    var updatedAt: Date = Date()
}

extension EnvVariable {
    var isKeyValid: Bool {
        let pattern = "^[a-zA-Z_][a-zA-Z0-9_]*$"
        guard let regex = try? NSRegularExpression(pattern: pattern) else { return false }
        let range = NSRange(key.startIndex..<key.endIndex, in: key)
        return regex.firstMatch(in: key, range: range) != nil
            && key.count >= 1
            && key.count <= 255
    }

    var isValueValid: Bool {
        value.count <= 10000
    }
}
