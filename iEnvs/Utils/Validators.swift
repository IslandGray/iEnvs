import Foundation

enum Validators {
    static func validateEnvKey(_ key: String) -> Bool {
        let pattern = "^[a-zA-Z_][a-zA-Z0-9_]*$"
        guard let regex = try? NSRegularExpression(pattern: pattern) else { return false }
        let range = NSRange(key.startIndex..<key.endIndex, in: key)
        return regex.firstMatch(in: key, range: range) != nil
            && key.count >= 1
            && key.count <= 255
    }

    static func validateGroupName(_ name: String) -> Bool {
        let invalidChars = CharacterSet(charactersIn: "/\\:")
        return name.count >= 1
            && name.count <= 50
            && name.rangeOfCharacter(from: invalidChars) == nil
    }
}
