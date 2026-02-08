import SwiftUI

@main
struct iEnvsApp: App {
    @StateObject private var viewModel = EnvGroupViewModel()
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        WindowGroup {
            MainView()
                .environmentObject(viewModel)
                .frame(minWidth: 800, minHeight: 500)
                .onAppear {
                    appDelegate.setupStatusBar(viewModel: viewModel)
                    // Capture and configure main window
                    DispatchQueue.main.async {
                        if appDelegate.mainWindow == nil {
                            if let window = NSApp.windows.first(where: { window in
                                window.level == .normal &&
                                window.canBecomeMain &&
                                window.title != "Settings" &&
                                window.title != "偏好设置"
                            }) {
                                appDelegate.mainWindow = window
                                window.delegate = appDelegate
                            }
                        }
                    }
                }
        }
        .defaultSize(width: 1000, height: 650)

        Settings {
            SettingsView()
        }
    }
}

@MainActor
class AppDelegate: NSObject, NSApplicationDelegate, NSWindowDelegate {
    private var statusBarManager: StatusBarManager?
    var mainWindow: NSWindow?
    private var settingsWindow: NSWindow?

    func setupStatusBar(viewModel: EnvGroupViewModel) {
        guard statusBarManager == nil else { return }
        statusBarManager = StatusBarManager(viewModel: viewModel, appDelegate: self)
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleOpenSettings),
            name: .openSettings,
            object: nil
        )
    }

    @objc private func handleOpenSettings() {
        openSettingsWindow()
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        return false
    }

    // Intercept window close: hide instead of destroy
    func windowShouldClose(_ sender: NSWindow) -> Bool {
        if sender === mainWindow {
            sender.orderOut(nil)
            // Hide dock icon
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                NSApp.setActivationPolicy(.accessory)
            }
            return false // Prevent actual close
        }
        return true
    }

    func showMainWindow() {
        NSApp.setActivationPolicy(.regular)
        NSApp.activate(ignoringOtherApps: true)

        if let window = mainWindow {
            window.makeKeyAndOrderFront(nil)
        }
    }

    func openSettingsWindow() {
        NSApp.setActivationPolicy(.regular)
        NSApp.activate(ignoringOtherApps: true)

        // Reuse existing settings window if it exists
        if let window = settingsWindow, window.isVisible {
            window.makeKeyAndOrderFront(nil)
            return
        }

        let settingsView = SettingsView()
        let hostingController = NSHostingController(rootView: settingsView)

        let window = NSWindow(contentViewController: hostingController)
        window.title = "偏好设置"
        window.styleMask = [.titled, .closable]
        window.setContentSize(NSSize(width: 600, height: 400))
        window.center()
        window.makeKeyAndOrderFront(nil)

        self.settingsWindow = window
    }
}
