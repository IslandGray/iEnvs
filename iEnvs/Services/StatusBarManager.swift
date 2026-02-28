import AppKit
import SwiftUI
import Combine

extension Notification.Name {
    static let openSettings = Notification.Name("iEnvs.openSettings")
}

@MainActor
final class StatusBarManager: NSObject {
    private var statusItem: NSStatusItem?
    private let viewModel: EnvGroupViewModel
    private let hostsViewModel: HostsGroupViewModel
    private var cancellables = Set<AnyCancellable>()
    private weak var appDelegate: AppDelegate?

    init(viewModel: EnvGroupViewModel, hostsViewModel: HostsGroupViewModel, appDelegate: AppDelegate) {
        self.viewModel = viewModel
        self.hostsViewModel = hostsViewModel
        self.appDelegate = appDelegate
        super.init()
        setupStatusBar()
        observeChanges()
    }

    private func setupStatusBar() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)

        if let button = statusItem?.button {
            if let image = NSImage(named: "StatusBarIcon") {
                image.isTemplate = true
                image.size = NSSize(width: 18, height: 18)
                button.image = image
            }
            button.toolTip = L10n.StatusBar.tooltip
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

        hostsViewModel.objectWillChange
            .debounce(for: .milliseconds(100), scheduler: RunLoop.main)
            .sink { [weak self] _ in
                self?.rebuildMenu()
            }
            .store(in: &cancellables)

        LocalizationManager.shared.objectWillChange
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
            let emptyItem = NSMenuItem(title: L10n.StatusBar.noGroups, action: nil, keyEquivalent: "")
            emptyItem.isEnabled = false
            menu.addItem(emptyItem)
        } else {
            for group in viewModel.groups {
                let hasConflict = viewModel.hasConflict(groupId: group.id)
                let conflictMark = hasConflict ? " ⚠️" : ""
                let title = "\(L10n.StatusBar.groupInfo(group.name, group.variables.count))\(conflictMark)"

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

        // Hosts Groups
        let hostsHeaderItem = NSMenuItem(title: L10n.Hosts.hostsSection, action: nil, keyEquivalent: "")
        hostsHeaderItem.attributedTitle = NSAttributedString(
            string: L10n.Hosts.hostsSection,
            attributes: [.font: NSFont.boldSystemFont(ofSize: 11)]
        )
        hostsHeaderItem.isEnabled = false
        menu.addItem(hostsHeaderItem)

        if hostsViewModel.hostsGroups.isEmpty {
            let emptyItem = NSMenuItem(title: L10n.StatusBar.noGroups, action: nil, keyEquivalent: "")
            emptyItem.isEnabled = false
            menu.addItem(emptyItem)
        } else {
            for group in hostsViewModel.hostsGroups {
                let hasConflict = hostsViewModel.hasConflict(groupId: group.id)
                let conflictMark = hasConflict ? " ⚠️" : ""
                let title = "\(L10n.Hosts.hostsGroupInfo(group.name, group.entries.count))\(conflictMark)"

                let item = NSMenuItem(
                    title: title,
                    action: #selector(toggleHostsGroupAction(_:)),
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
            title: L10n.StatusBar.syncToShell,
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
            title: L10n.StatusBar.openMainWindow,
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
            title: L10n.StatusBar.preferences,
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
            title: L10n.StatusBar.quit,
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

    @objc private func toggleHostsGroupAction(_ sender: NSMenuItem) {
        guard let groupId = sender.representedObject as? UUID else { return }
        hostsViewModel.toggleHostsGroup(id: groupId)
    }

    @objc private func syncShellConfig() {
        // Trigger a save which syncs shell config
        viewModel.saveData()
        hostsViewModel.syncHostsFile()
    }

    @objc private func openMainWindow() {
        appDelegate?.showMainWindow()
    }

    @objc private func openSettings() {
        NSApp.setActivationPolicy(.regular)
        NSApp.activate(ignoringOtherApps: true)
        NotificationCenter.default.post(name: .openSettings, object: nil)
    }

    @objc private func quitApp() {
        NSApp.terminate(nil)
    }
}
