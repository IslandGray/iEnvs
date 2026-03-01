# iEnvs

📖 [中文文档](README.zh-CN.md)

A native macOS app for visually managing shell environment variables. Create, organize, and switch between different environment variable configurations through an intuitive GUI—no more tedious command-line operations or manual config file editing.

![Platform](https://img.shields.io/badge/platform-macOS%2013.0%2B-blue)
![Swift](https://img.shields.io/badge/Swift-5.9%2B-orange)
![License](https://img.shields.io/badge/license-Apache%202.0-green)

## Features

### Environment Variable Management
- **Group Management** — Organize environment variables into groups by project or scenario
- **One-Click Toggle** — Enable/disable groups with a switch; automatically writes to Shell config files
- **Conflict Detection** — Automatic warnings when multiple groups contain variables with the same name
- **Sensitive Data Protection** — Mark sensitive variables to hide them in the UI

### Hosts File Management (New in v1.1.0)
- **Hosts Group Management** — Create, edit, and delete hosts groups with enable/disable toggle
- **Hosts Entry Management** — Add, edit, and delete hosts entries (IP address, hostname, comment)
- **Conflict Detection** — Automatic detection of IP address or hostname conflicts
- **Auto Sync** — Enabled groups automatically write to `/etc/hosts`, disabled groups auto-remove
- **Menu Bar Integration** — Quick toggle hosts groups from the system menu bar

### Existing Config Import (New in v1.1.0)
- **Auto Detection** — Scan `~/.zshrc`, `~/.bashrc`, and `/etc/hosts` for unmanaged configurations
- **One-Click Migration** — Import existing environment variables and hosts entries into iEnvs
- **Direct Cleanup** — Option to directly delete unmanaged entries without importing
- **Real-time Badge** — Toolbar shows count of detected unmanaged configurations

### General Features
- **Import & Export** — Support for JSON format backup and team sharing
- **Auto Backup** — Creates backups before every system file modification
- **Search & Filter** — Global search across group names, variable names, and values
- **Dark Mode** — Automatically follows system appearance
- **Bilingual Support** — Full Chinese and English localization

## Screenshots

![iEnvs Screenshot](homepage.png)

## System Requirements

- macOS 13.0 (Ventura) or later
- Supports both Intel and Apple Silicon

## Installation

### Build from Source

```bash
# Clone the repository
git clone https://github.com/yourname/ienvs.git
cd ienvs

# Install XcodeGen (one-time)
brew install xcodegen

# Generate Xcode project and open
xcodegen generate
open iEnvs.xcodeproj
```

Press `Cmd+R` in Xcode to build and run.

Or use the setup script for one-click setup:

```bash
./setup.sh
```

### Command Line Build

```bash
xcodebuild -project iEnvs.xcodeproj -scheme iEnvs -configuration Release build SYMROOT=build
```

The built app will be located at `build/Build/Products/Release/iEnvs.app`.

## Usage

### Quick Start

1. Open iEnvs, click the **"+"** button at the bottom left to create a new group (e.g., "Frontend Development")
2. Add environment variables in the right panel (e.g., `NODE_ENV=development`)
3. Toggle the switch next to the group, and iEnvs will automatically write the variables to `~/.zshrc`
4. Run `source ~/.zshrc` in your terminal to apply the changes

### Shell Configuration File

iEnvs maintains marked sections in your system configuration files:

**Shell Configuration** (`~/.zshrc` or `~/.bashrc`):
```bash
# ========== iEnvs Managed Variables ==========
# [iEnvs:UUID] START - Group Name
export NODE_ENV=development
export API_KEY="your-api-key"
# [iEnvs:UUID] END - Group Name
# ========== End of iEnvs Managed Variables ==========
```

**Hosts File** (`/etc/hosts`):
```
# ========== iEnvs Managed Hosts ==========
# [iEnvs:UUID] START - Group Name
192.168.1.100 dev.local
127.0.0.1 test.example.com
# [iEnvs:UUID] END - Group Name
# ========== End of iEnvs Managed Hosts ==========
```

Supported Shells:
- **Zsh** (macOS default) — writes to `~/.zshrc`
- **Bash** — writes to `~/.bashrc` or `~/.bash_profile`

### Keyboard Shortcuts

| Shortcut | Action |
|----------|--------|
| `Cmd+N` | New Group |
| `Cmd+F` | Search |
| `Cmd+,` | Open Settings |
| `Cmd+Delete` | Delete Selected Item |
| `Cmd+Z` | Undo |

### Import & Export

- **Export as JSON** — Complete group configuration, suitable for backup and team sharing
- **Export as Shell Script** — Generates a `.sh` file that can be directly sourced
- **Import from JSON** — Supports skipping, overwriting, or renaming conflicting groups

## Tech Stack

| Technology | Purpose |
|------------|---------|
| Swift 5.9+ | Programming Language |
| SwiftUI | Native UI Framework |
| Foundation | Core System Library |
| XcodeGen | Project File Generation |

Pure native implementation, no third-party dependencies, no network requests, fully offline.

## Project Structure

```
iEnvs/
├── Models/                 # Data models (EnvGroup, EnvVariable, HostsGroup, HostsEntry, AppSettings, etc.)
├── ViewModels/             # View models (EnvGroupViewModel, HostsGroupViewModel, SettingsViewModel)
├── Views/                  # SwiftUI views
│   ├── Sidebar/            # Left sidebar (Env + Hosts groups)
│   ├── EnvDetail/          # Environment variable details
│   ├── HostsDetail/        # Hosts entry details (New in v1.1.0)
│   ├── Settings/           # Settings interface
│   ├── Dialogs/            # Dialogs
│   └── Components/         # Reusable components
├── Services/               # Business logic
│   ├── DataStore.swift
│   ├── ShellConfigManager.swift
│   ├── HostsFileManager.swift      # Hosts file I/O (New in v1.1.0)
│   ├── BackupManager.swift
│   ├── ConflictDetector.swift
│   ├── HostsConflictDetector.swift # Hosts conflict detection (New in v1.1.0)
│   └── ImportExportManager.swift
├── Utils/                  # Utilities (Constants, Validators, HostsValidators, Logger)
└── Resources/              # Resources (Assets, Info.plist, Entitlements)
```

## Data Storage

- App Data: `~/Library/Application Support/iEnvs/data.json`
- Config Backups: `~/Library/Application Support/iEnvs/backups/`
- Logs: `~/Library/Logs/iEnvs/`

## Documentation

- [Product Requirements Document (PRD)](docs/PRD.md)
- [System Design Document](docs/SystemDesign.md)

## License

Apache License 2.0
