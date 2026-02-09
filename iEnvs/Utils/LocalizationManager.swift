import Foundation
import SwiftUI

@MainActor
final class LocalizationManager: ObservableObject {
    static let shared = LocalizationManager()

    /// Thread-safe access to current language for use in L10n
    nonisolated(unsafe) static var currentLanguage: AppLanguage = .zh

    @Published var language: AppLanguage {
        didSet {
            LocalizationManager.currentLanguage = language
        }
    }

    private init() {
        let appData = DataStore.shared.load()
        self.language = appData.settings.language
        LocalizationManager.currentLanguage = appData.settings.language
    }

    func setLanguage(_ lang: AppLanguage) {
        language = lang
        var appData = DataStore.shared.load()
        appData.settings.language = lang
        DataStore.shared.save(appData)
    }
}
