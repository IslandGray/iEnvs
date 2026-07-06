import Foundation

struct EnvVariable: Identifiable, Equatable {
    var id: UUID = UUID()
    var key: String
    var value: String
    var isSensitive: Bool = false
    var isLiteral: Bool = true
    var createdAt: Date = Date()
    var updatedAt: Date = Date()
}

extension EnvVariable: Codable {
    enum CodingKeys: String, CodingKey {
        case id, key, value, isSensitive, isLiteral, createdAt, updatedAt
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        key = try container.decode(String.self, forKey: .key)
        value = try container.decode(String.self, forKey: .value)
        isSensitive = try container.decodeIfPresent(Bool.self, forKey: .isSensitive) ?? false
        isLiteral = try container.decodeIfPresent(Bool.self, forKey: .isLiteral) ?? true
        createdAt = try container.decodeIfPresent(Date.self, forKey: .createdAt) ?? Date()
        updatedAt = try container.decodeIfPresent(Date.self, forKey: .updatedAt) ?? Date()
    }
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
