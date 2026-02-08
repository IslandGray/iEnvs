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
                }
        }
        .defaultSize(width: 1000, height: 650)

        Settings {
            SettingsView()
        }
    }
}

@MainActor
class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusBarManager: StatusBarManager?

    func setupStatusBar(viewModel: EnvGroupViewModel) {
        guard statusBarManager == nil else { return }
        statusBarManager = StatusBarManager(viewModel: viewModel)

        // Observe window close to hide dock icon
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(windowDidClose),
            name: NSWindow.willCloseNotification,
            object: nil
        )
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        return false
    }

    @objc func windowDidClose(_ notification: Notification) {
        // Delay check to let window fully close
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            let visibleWindows = NSApp.windows.filter {
                $0.isVisible && $0.level == .normal && $0.canBecomeMain
            }
            if visibleWindows.isEmpty {
                NSApp.setActivationPolicy(.accessory)
            }
        }
    }

    @objc func newMainWindow() {
        // Trigger SwiftUI WindowGroup to open a new window
        NSApp.sendAction(Selector(("newWindowForTab:")), to: nil, from: nil)
    }
}
