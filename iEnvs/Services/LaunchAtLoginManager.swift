import Foundation
import ServiceManagement

/// 管理应用开机自启动
@MainActor
final class LaunchAtLoginManager {
    static let shared = LaunchAtLoginManager()

    private let bundleIdentifier = "com.ienvs.app"

    private init() {}

    /// 检查是否已启用开机自启动
    var isEnabled: Bool {
        // 使用 SMAppService 检查主应用状态
        let service = SMAppService.mainApp
        return service.status == .enabled
    }

    /// 启用开机自启动
    func enable() throws {
        let service = SMAppService.mainApp

        // 如果已经启用，先禁用再重新注册
        if service.status == .enabled {
            try? service.unregister()
        }

        try service.register()

        Logger.shared.info("Launch at login enabled")
    }

    /// 禁用开机自启动
    func disable() throws {
        let service = SMAppService.mainApp

        if service.status == .enabled {
            try service.unregister()
        }

        Logger.shared.info("Launch at login disabled")
    }

    /// 切换开机自启动状态
    func toggle() throws {
        if isEnabled {
            try disable()
        } else {
            try enable()
        }
    }

    /// 同步设置状态（在应用启动时调用）
    func syncWithSettings(_ enabled: Bool) {
        let currentStatus = isEnabled

        if enabled != currentStatus {
            do {
                if enabled {
                    try enable()
                } else {
                    try disable()
                }
            } catch {
                Logger.shared.error("Failed to sync launch at login setting: \(error.localizedDescription)")
            }
        }
    }
}
