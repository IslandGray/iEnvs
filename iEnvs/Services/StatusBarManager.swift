import AppKit
import SwiftUI
import Combine

@MainActor
final class StatusBarManager: NSObject {
    private var statusItem: NSStatusItem?
    private let viewModel: EnvGroupViewModel
    private var cancellables = Set<AnyCancellable>()
    private weak var appDelegate: AppDelegate?

    init(viewModel: EnvGroupViewModel, appDelegate: AppDelegate) {
        self.viewModel = viewModel
        self.appDelegate = appDelegate
        super.init()
        setupStatusBar()
        observeChanges()
    }

    private func setupStatusBar() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)

        if let button = statusItem?.button {
            if let image = NSImage(systemSymbolName: "terminal.fill", accessibilityDescription: "iEnvs") {
                image.isTemplate = true
                button.image = image
            }
            button.toolTip = "iEnvs - 环境变量管理"
        }

        rebuildMenu()
    }

    private func observeChanges() {
        viewModel.objectWillChange
            .debounce(for: .milliseconds(100), scheduler: RunLoop.main)
            .sink { [weak self] _ in
                self?.rebuildMenu()
            }
            .store(in: &cancellables)
    }

    private func rebuildMenu() {
        let menu = NSMenu()

        // Header
        let headerItem = NSMenuItem(title: "iEnvs", action: nil, keyEquivalent: "")
        headerItem.attributedTitle = NSAttributedString(
            string: "iEnvs",
            attributes: [.font: NSFont.boldSystemFont(ofSize: 13)]
        )
        headerItem.isEnabled = false
        menu.addItem(headerItem)
        menu.addItem(NSMenuItem.separator())

        // Groups
        if viewModel.groups.isEmpty {
            let emptyItem = NSMenuItem(title: "暂无分组", action: nil, keyEquivalent: "")
            emptyItem.isEnabled = false
            menu.addItem(emptyItem)
        } else {
            for group in viewModel.groups {
                let hasConflict = viewModel.hasConflict(groupId: group.id)
                let conflictMark = hasConflict ? " ⚠️" : ""
                let title = "\(group.name) (\(group.variables.count)个变量)\(conflictMark)"

                let item = NSMenuItem(
                    title: title,
                    action: #selector(toggleGroupAction(_:)),
                    keyEquivalent: ""
                )
                item.target = self
                item.state = group.isEnabled ? .on : .off
                item.representedObject = group.id
                menu.addItem(item)
            }
        }

        menu.addItem(NSMenuItem.separator())

        // Sync action
        let syncItem = NSMenuItem(
            title: "同步到 Shell 配置",
            action: #selector(syncShellConfig),
            keyEquivalent: "s"
        )
        syncItem.keyEquivalentModifierMask = [.command, .shift]
        syncItem.target = self
        if let syncImage = NSImage(systemSymbolName: "arrow.triangle.2.circlepath", accessibilityDescription: nil) {
            syncImage.isTemplate = true
            syncItem.image = syncImage
        }
        menu.addItem(syncItem)

        // Open main window
        let openItem = NSMenuItem(
            title: "打开主窗口",
            action: #selector(openMainWindow),
            keyEquivalent: "o"
        )
        openItem.keyEquivalentModifierMask = [.command]
        openItem.target = self
        if let openImage = NSImage(systemSymbolName: "macwindow", accessibilityDescription: nil) {
            openImage.isTemplate = true
            openItem.image = openImage
        }
        menu.addItem(openItem)

        menu.addItem(NSMenuItem.separator())

        // Preferences
        let prefsItem = NSMenuItem(
            title: "偏好设置...",
            action: #selector(openSettings),
            keyEquivalent: ","
        )
        prefsItem.keyEquivalentModifierMask = [.command]
        prefsItem.target = self
        if let prefsImage = NSImage(systemSymbolName: "gearshape", accessibilityDescription: nil) {
            prefsImage.isTemplate = true
            prefsItem.image = prefsImage
        }
        menu.addItem(prefsItem)

        menu.addItem(NSMenuItem.separator())

        // Quit
        let quitItem = NSMenuItem(
            title: "退出 iEnvs",
            action: #selector(quitApp),
            keyEquivalent: "q"
        )
        quitItem.keyEquivalentModifierMask = [.command]
        quitItem.target = self
        menu.addItem(quitItem)

        statusItem?.menu = menu
    }

    // MARK: - Actions

    @objc private func toggleGroupAction(_ sender: NSMenuItem) {
        guard let groupId = sender.representedObject as? UUID else { return }
        viewModel.toggleGroup(id: groupId)
    }

    @objc private func syncShellConfig() {
        // Trigger a save which syncs shell config
        viewModel.saveData()
    }

    @objc private func openMainWindow() {
        appDelegate?.showMainWindow()
    }

    @objc private func openSettings() {
        NSApp.activate(ignoringOtherApps: true)
        // Use the standard macOS settings action
        if #available(macOS 14.0, *) {
            NSApp.sendAction(Selector(("showSettingsWindow:")), to: nil, from: nil)
        } else {
            NSApp.sendAction(Selector(("showPreferencesWindow:")), to: nil, from: nil)
        }
    }

    @objc private func quitApp() {
        NSApp.terminate(nil)
    }
}
