# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

iEnvs is a native macOS app for visually managing shell environment variables. It lets users create groups of env vars, toggle them on/off, and automatically syncs enabled groups into `~/.zshrc` or `~/.bashrc` using special comment markers.

- **Language:** Swift 5.9+
- **UI Framework:** SwiftUI (macOS 13.0+ / Ventura)
- **Architecture:** MVVM
- **Data Storage:** JSON file at `~/Library/Application Support/iEnvs/data.json`
- **Dependencies:** None (pure native, no third-party libraries, no network)
- **Sandbox:** Disabled (`com.apple.security.app-sandbox = false`) to access shell config files

## Build & Run

```bash
# Generate Xcode project (requires xcodegen)
brew install xcodegen   # one-time
xcodegen generate

# Open in Xcode
open iEnvs.xcodeproj

# Build from command line
xcodebuild -project iEnvs.xcodeproj -scheme iEnvs -configuration Release build SYMROOT=build

# Or use the setup script
./setup.sh
```

There are no tests yet. The project uses `project.yml` (XcodeGen) to define the Xcode project — regenerate with `xcodegen generate` after adding/removing source files.

## Architecture

```
View (SwiftUI) → ViewModel (@StateObject/@ObservedObject) → Services → Models
```

### Key Data Flow

1. `iEnvsApp.swift` creates `EnvGroupViewModel` as `@StateObject`, passes it via `.environmentObject`
2. `EnvGroupViewModel` is the central coordinator — manages groups, variables, conflict detection, and shell sync
3. When a group is toggled, `ShellConfigManager` writes/removes export blocks in the shell config file
4. `DataStore` persists all data as JSON; `BackupManager` backs up shell configs before modification

### Shell Config Integration

The app manages a marked section in `~/.zshrc` (or `~/.bashrc`):

```bash
# ========== iEnvs Managed Variables ==========
# [iEnvs:{UUID}] START - GroupName
export KEY=VALUE
# [iEnvs:{UUID}] END - GroupName
# ========== End of iEnvs Managed Variables ==========
```

Groups are identified by UUID in the config file, so renaming a group doesn't break sync. The marker constants are defined in `Utils/Constants.swift`.

### Module Responsibilities

| Layer | Directory | Key Files |
|-------|-----------|-----------|
| **Models** | `iEnvs/Models/` | `EnvGroup`, `EnvVariable`, `AppSettings`, `AppData`, `ShellType` |
| **ViewModels** | `iEnvs/ViewModels/` | `EnvGroupViewModel` (main), `SettingsViewModel` |
| **Views** | `iEnvs/Views/` | `MainView` (NavigationSplitView), Sidebar/, Detail/, Settings/, Dialogs/ |
| **Services** | `iEnvs/Services/` | `DataStore` (JSON persistence), `ShellConfigManager` (shell file I/O), `BackupManager`, `ConflictDetector`, `ImportExportManager` |
| **Utils** | `iEnvs/Utils/` | `Constants` (markers, paths), `Validators`, `Logger` |

### Important Paths (Runtime)

- App data: `~/Library/Application Support/iEnvs/data.json`
- Backups: `~/Library/Application Support/iEnvs/backups/`
- Logs: `~/Library/Logs/iEnvs/`

## Conventions

- All user-facing text is in Chinese (zh-CN)
- `DataStore` and `BackupManager` are singletons (`.shared`)
- Environment variable key validation: `^[a-zA-Z_][a-zA-Z0-9_]*$`, max 255 chars
- Values are exported with double quotes only when they contain spaces, `$`, `*`, `?`, or `~`
- Shell config writes use atomic temp-file-then-replace pattern with pre-write backup
