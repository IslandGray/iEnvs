import Foundation

final class DataStore {
    // MARK: - Singleton
    static let shared = DataStore()

    // MARK: - Properties
    private let fileURL: URL
    private let fileManager = FileManager.default

    // MARK: - Initialization
    private init() {
        let appSupportDir = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        let iEnvsDir = appSupportDir.appendingPathComponent("iEnvs", isDirectory: true)

        // 确保目录存在
        try? fileManager.createDirectory(at: iEnvsDir, withIntermediateDirectories: true)

        self.fileURL = iEnvsDir.appendingPathComponent("data.json")
    }

    // MARK: - Public Methods

    /// 加载应用数据
    func load() -> AppData {
        do {
            guard fileManager.fileExists(atPath: fileURL.path) else {
                // 首次启动，返回默认数据
                let defaultData = AppData.default
                save(defaultData)
                return defaultData
            }

            let data = try Data(contentsOf: fileURL)
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601

            return try decoder.decode(AppData.self, from: data)
        } catch {
            print("DataStore.load() error: \(error.localizedDescription)")
            return AppData.default
        }
    }

    /// 保存应用数据
    func save(_ appData: AppData) {
        do {
            var updatedData = appData
            updatedData.lastSavedAt = Date()

            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .iso8601
            encoder.outputFormatting = [.prettyPrinted, .sortedKeys]

            let data = try encoder.encode(updatedData)
            try data.write(to: fileURL, options: .atomic)
        } catch {
            print("DataStore.save() error: \(error.localizedDescription)")
        }
    }
}
