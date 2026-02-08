# iEnvs 系统设计文档

**版本：** 1.0
**日期：** 2026-02-08
**作者：** Architecture Team

---

## 1. 技术选型与架构概述

### 1.1 核心技术栈

| 技术 | 版本 | 用途 |
|------|------|------|
| **Swift** | 5.9+ | 应用开发语言 |
| **SwiftUI** | macOS 13+ | 原生 UI 框架 |
| **Foundation** | macOS 13+ | 核心系统库 |
| **Combine** | macOS 13+ | 响应式编程（可选） |

### 1.2 架构选择：MVVM

**采用 MVVM（Model-View-ViewModel）架构模式：**

```
┌─────────────────────────────────────────────────────────────┐
│                          View Layer                         │
│  (SwiftUI Views - MainView, SidebarView, DetailView...)    │
└────────────────────┬────────────────────────────────────────┘
                     │ @StateObject / @ObservedObject
                     │ Binding
┌────────────────────▼────────────────────────────────────────┐
│                     ViewModel Layer                          │
│  (EnvGroupViewModel, SettingsViewModel)                     │
│  - Business Logic                                            │
│  - State Management                                          │
│  - Coordination                                              │
└────────────────────┬────────────────────────────────────────┘
                     │ Calls
┌────────────────────▼────────────────────────────────────────┐
│                      Service Layer                           │
│  (ShellConfigManager, DataStore, BackupManager)             │
│  - I/O Operations                                            │
│  - File Management                                           │
│  - Business Rules                                            │
└────────────────────┬────────────────────────────────────────┘
                     │ Uses
┌────────────────────▼────────────────────────────────────────┐
│                       Model Layer                            │
│  (EnvGroup, EnvVariable, AppSettings)                       │
│  - Data Structures                                           │
│  - Codable Conformance                                       │
└─────────────────────────────────────────────────────────────┘
```

**选择 MVVM 的理由：**

1. **SwiftUI 原生支持**：SwiftUI 天然适配 MVVM，通过 `@Published`、`ObservableObject` 实现数据绑定
2. **职责分离**：View 专注 UI 渲染，ViewModel 处理业务逻辑，Model 存储数据
3. **可测试性**：ViewModel 可脱离 UI 进行单元测试
4. **代码复用**：多个 View 可共享同一 ViewModel

### 1.3 数据持久化：JSON 文件存储

**为什么选择 JSON 文件而不是 Core Data？**

| 因素 | JSON 文件 | Core Data |
|------|----------|-----------|
| **复杂度** | ✅ 极低，直接 Codable | ❌ 需要定义 .xcdatamodeld |
| **可读性** | ✅ 人类可读，便于调试 | ❌ SQLite 二进制格式 |
| **数据迁移** | ✅ 简单的 JSON 版本控制 | ❌ 复杂的 Model 迁移 |
| **依赖性** | ✅ 零依赖 | ⚠️ 依赖 CoreData 框架 |
| **数据规模** | ⚠️ 适合小规模（<10MB） | ✅ 适合大规模 |
| **查询能力** | ❌ 需要手动过滤 | ✅ 强大的谓词查询 |
| **iEnvs 场景** | ✅ 完全满足需求 | ⚠️ 过度设计 |

**结论**：iEnvs 数据量小（预计数百个变量），操作频率低，JSON 文件完全满足需求，且调试友好。

### 1.4 整体架构图

```
┌──────────────────────────────────────────────────────────────┐
│                       iEnvs Application                      │
├──────────────────────────────────────────────────────────────┤
│                                                              │
│  ┌────────────┐  ┌─────────────┐  ┌──────────────┐         │
│  │  MainView  │  │ SettingsView│  │ ImportExport │         │
│  │  (双栏布局) │  │  (设置面板)  │  │   (导入导出)  │         │
│  └─────┬──────┘  └──────┬──────┘  └──────┬───────┘         │
│        │                │                │                  │
│  ┌─────▼────────────────▼────────────────▼───────┐         │
│  │         EnvGroupViewModel                      │         │
│  │  - groups: [EnvGroup]                          │         │
│  │  - enableGroup() / disableGroup()              │         │
│  │  - detectConflicts()                           │         │
│  └─────┬──────────────────────────────────────────┘         │
│        │                                                     │
│  ┌─────▼─────────────────────────────────────────┐         │
│  │              Service Layer                     │         │
│  │  ┌──────────────┐  ┌──────────────┐           │         │
│  │  │  DataStore   │  │ShellConfig   │           │         │
│  │  │  (JSON读写)   │  │Manager       │           │         │
│  │  └──────────────┘  │(.zshrc管理)   │           │         │
│  │  ┌──────────────┐  └──────────────┘           │         │
│  │  │BackupManager │                              │         │
│  │  │(备份管理)     │                              │         │
│  │  └──────────────┘                              │         │
│  └────────────────────────────────────────────────┘         │
│                                                              │
├──────────────────────────────────────────────────────────────┤
│                      File System                             │
│  ~/Library/Application Support/iEnvs/                       │
│    ├── data.json              (应用数据)                     │
│    ├── backups/               (配置文件备份)                 │
│    └── logs/                  (日志文件)                     │
│                                                              │
│  ~/.zshrc 或 ~/.bashrc        (Shell 配置文件)              │
└──────────────────────────────────────────────────────────────┘
```

---

## 2. 项目工程结构

### 2.1 目录结构设计

```
iEnvs/
├── iEnvs.xcodeproj/                # Xcode 项目文件
├── iEnvs/                          # 源代码目录
│   ├── iEnvsApp.swift              # 应用入口 (@main)
│   │
│   ├── Models/                     # 数据模型层
│   │   ├── EnvGroup.swift          # 环境变量分组模型
│   │   ├── EnvVariable.swift       # 环境变量模型
│   │   ├── AppSettings.swift       # 应用设置模型
│   │   ├── AppData.swift           # 顶层数据容器
│   │   └── ShellType.swift         # Shell 类型枚举
│   │
│   ├── ViewModels/                 # 视图模型层
│   │   ├── EnvGroupViewModel.swift # 分组管理视图模型
│   │   ├── SettingsViewModel.swift # 设置管理视图模型
│   │   └── ImportExportViewModel.swift # 导入导出视图模型
│   │
│   ├── Views/                      # 视图层
│   │   ├── MainView.swift          # 主窗口（NavigationSplitView）
│   │   │
│   │   ├── Sidebar/                # 左侧分组列表
│   │   │   ├── SidebarView.swift   # 分组列表容器
│   │   │   ├── GroupRowView.swift  # 单个分组行
│   │   │   └── GroupToolbar.swift  # 底部工具栏
│   │   │
│   │   ├── Detail/                 # 右侧变量详情
│   │   │   ├── DetailView.swift    # 详情容器
│   │   │   ├── VariableListView.swift # 变量列表
│   │   │   ├── VariableRowView.swift  # 单个变量行
│   │   │   ├── VariableEditView.swift # 变量编辑器
│   │   │   └── EmptyStateView.swift   # 空状态占位
│   │   │
│   │   ├── Settings/               # 设置界面
│   │   │   ├── SettingsView.swift  # 设置主窗口
│   │   │   ├── GeneralSettings.swift  # 通用设置
│   │   │   ├── ShellSettings.swift    # Shell 设置
│   │   │   └── BackupSettings.swift   # 备份设置
│   │   │
│   │   ├── Dialogs/                # 对话框组件
│   │   │   ├── ConflictWarningView.swift # 冲突警告
│   │   │   ├── ConfirmDeleteView.swift   # 删除确认
│   │   │   └── WelcomeGuideView.swift    # 欢迎向导
│   │   │
│   │   └── Components/             # 可复用组件
│   │       ├── SearchBar.swift     # 搜索框
│   │       ├── ToolbarButton.swift # 工具栏按钮
│   │       └── StatusIndicator.swift # 状态指示器
│   │
│   ├── Services/                   # 服务层（业务逻辑）
│   │   ├── ShellConfigManager.swift   # Shell 配置文件管理
│   │   ├── DataStore.swift            # 数据持久化服务
│   │   ├── BackupManager.swift        # 备份管理服务
│   │   ├── ConflictDetector.swift     # 冲突检测服务
│   │   └── ImportExportManager.swift  # 导入导出服务
│   │
│   ├── Utils/                      # 工具类
│   │   ├── Validators.swift        # 输入验证工具
│   │   ├── FileSystemHelper.swift  # 文件系统辅助
│   │   ├── Logger.swift            # 日志记录
│   │   └── Constants.swift         # 全局常量
│   │
│   └── Resources/                  # 资源文件
│       ├── Assets.xcassets         # 图标、颜色等资源
│       ├── Info.plist              # 应用配置
│       └── Localizable.strings     # 本地化字符串
│
├── iEnvsTests/                     # 单元测试
│   ├── ModelTests/
│   ├── ViewModelTests/
│   └── ServiceTests/
│
├── iEnvsUITests/                   # UI 测试
│   └── iEnvsUITests.swift
│
├── docs/                           # 文档目录
│   ├── PRD.md                      # 产品需求文档
│   ├── SystemDesign.md             # 系统设计文档（本文件）
│   └── API.md                      # API 设计文档
│
└── README.md                       # 项目说明
```

### 2.2 模块职责说明

| 目录 | 职责 | 依赖关系 |
|------|------|---------|
| **Models/** | 纯数据结构，实现 Codable/Identifiable | 无依赖 |
| **ViewModels/** | 状态管理、业务逻辑协调 | 依赖 Models、Services |
| **Views/** | UI 渲染、用户交互 | 依赖 ViewModels |
| **Services/** | 文件 I/O、Shell 配置、数据存储 | 依赖 Models |
| **Utils/** | 通用工具函数、验证逻辑 | 无依赖 |

---

## 3. 数据模型设计

### 3.1 核心模型定义

#### 3.1.1 EnvVariable（环境变量）

```swift
import Foundation

struct EnvVariable: Identifiable, Codable, Equatable {
    /// 唯一标识符
    let id: UUID

    /// 变量名（大小写敏感）
    var key: String

    /// 变量值
    var value: String

    /// 是否为敏感信息（如 API Key、密码）
    var isSensitive: Bool

    /// 创建时间
    let createdAt: Date

    /// 最后修改时间
    var updatedAt: Date

    init(
        id: UUID = UUID(),
        key: String,
        value: String,
        isSensitive: Bool = false,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.key = key
        self.value = value
        self.isSensitive = isSensitive
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}

// MARK: - Validation
extension EnvVariable {
    /// 验证变量名是否合法
    var isKeyValid: Bool {
        let pattern = "^[a-zA-Z_][a-zA-Z0-9_]*$"
        let regex = try? NSRegularExpression(pattern: pattern)
        let range = NSRange(key.startIndex..<key.endIndex, in: key)
        return regex?.firstMatch(in: key, range: range) != nil
            && key.count >= 1
            && key.count <= 255
    }

    /// 验证变量值是否合法
    var isValueValid: Bool {
        value.count <= 10000
    }
}
```

#### 3.1.2 EnvGroup（环境变量分组）

```swift
import Foundation

struct EnvGroup: Identifiable, Codable, Equatable {
    /// 唯一标识符（用于标记配置文件中的区域）
    let id: UUID

    /// 分组名称（用户可见）
    var name: String

    /// 分组描述
    var description: String

    /// 是否启用（写入到 shell 配置文件）
    var isEnabled: Bool

    /// 分组内的环境变量列表
    var variables: [EnvVariable]

    /// 显示顺序（用于 UI 排序）
    var order: Int

    /// 创建时间
    let createdAt: Date

    /// 最后修改时间
    var updatedAt: Date

    init(
        id: UUID = UUID(),
        name: String,
        description: String = "",
        isEnabled: Bool = false,
        variables: [EnvVariable] = [],
        order: Int = 0,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.name = name
        self.description = description
        self.isEnabled = isEnabled
        self.variables = variables
        self.order = order
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}

// MARK: - Computed Properties
extension EnvGroup {
    /// 变量数量
    var variableCount: Int {
        variables.count
    }

    /// 是否包含冲突（与其他分组）
    var hasConflicts: Bool {
        // 由 ViewModel 设置
        false
    }
}
```

#### 3.1.3 ShellType（Shell 类型）

```swift
import Foundation

enum ShellType: String, Codable, CaseIterable, Identifiable {
    case bash
    case zsh

    var id: String { rawValue }

    /// Shell 显示名称
    var displayName: String {
        switch self {
        case .bash: return "Bash"
        case .zsh: return "Zsh"
        }
    }

    /// 默认配置文件路径
    var defaultConfigPath: String {
        let homeDir = FileManager.default.homeDirectoryForCurrentUser.path
        switch self {
        case .bash:
            // 优先使用 .bashrc，如果不存在则使用 .bash_profile
            let bashrc = "\(homeDir)/.bashrc"
            let bashProfile = "\(homeDir)/.bash_profile"
            return FileManager.default.fileExists(atPath: bashrc) ? bashrc : bashProfile
        case .zsh:
            return "\(homeDir)/.zshrc"
        }
    }

    /// 检测当前系统默认 Shell
    static func detectCurrent() -> ShellType {
        let shellPath = ProcessInfo.processInfo.environment["SHELL"] ?? ""
        if shellPath.contains("zsh") {
            return .zsh
        } else if shellPath.contains("bash") {
            return .bash
        } else {
            // macOS 13+ 默认是 zsh
            return .zsh
        }
    }
}
```

#### 3.1.4 AppSettings（应用设置）

```swift
import Foundation

struct AppSettings: Codable, Equatable {
    /// Shell 类型
    var shellType: ShellType

    /// 配置文件路径（可自定义）
    var configFilePath: String

    /// 是否自动备份
    var autoBackup: Bool

    /// 最大备份文件数量
    var maxBackupCount: Int

    /// 主题模式
    var theme: ThemeMode

    /// 启用冲突检测
    var enableConflictDetection: Bool

    /// 启用正则搜索
    var enableRegexSearch: Bool

    /// 导出时包含禁用分组
    var exportIncludesDisabledGroups: Bool

    init(
        shellType: ShellType = .detectCurrent(),
        configFilePath: String = "",
        autoBackup: Bool = true,
        maxBackupCount: Int = 10,
        theme: ThemeMode = .auto,
        enableConflictDetection: Bool = true,
        enableRegexSearch: Bool = false,
        exportIncludesDisabledGroups: Bool = false
    ) {
        self.shellType = shellType
        self.configFilePath = configFilePath.isEmpty ? shellType.defaultConfigPath : configFilePath
        self.autoBackup = autoBackup
        self.maxBackupCount = max(5, min(20, maxBackupCount))
        self.theme = theme
        self.enableConflictDetection = enableConflictDetection
        self.enableRegexSearch = enableRegexSearch
        self.exportIncludesDisabledGroups = exportIncludesDisabledGroups
    }
}

enum ThemeMode: String, Codable, CaseIterable, Identifiable {
    case auto
    case light
    case dark

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .auto: return "自动"
        case .light: return "浅色"
        case .dark: return "深色"
        }
    }
}
```

#### 3.1.5 AppData（顶层数据容器）

```swift
import Foundation

struct AppData: Codable {
    /// 数据格式版本（用于未来迁移）
    var version: String

    /// 所有分组
    var groups: [EnvGroup]

    /// 应用设置
    var settings: AppSettings

    /// 最后保存时间
    var lastSavedAt: Date

    init(
        version: String = "1.0",
        groups: [EnvGroup] = [],
        settings: AppSettings = AppSettings(),
        lastSavedAt: Date = Date()
    ) {
        self.version = version
        self.groups = groups
        self.settings = settings
        self.lastSavedAt = lastSavedAt
    }
}

// MARK: - Default Data
extension AppData {
    /// 默认数据（用于首次启动）
    static var `default`: AppData {
        AppData(
            groups: [
                EnvGroup(
                    name: "示例分组",
                    description: "这是一个示例分组，你可以删除它",
                    isEnabled: false,
                    variables: [
                        EnvVariable(key: "EXAMPLE_VAR", value: "example_value")
                    ],
                    order: 0
                )
            ]
        )
    }
}
```

### 3.2 数据模型关系图

```
AppData (顶层容器)
├── version: String
├── lastSavedAt: Date
├── settings: AppSettings
│   ├── shellType: ShellType (enum)
│   ├── configFilePath: String
│   ├── autoBackup: Bool
│   ├── maxBackupCount: Int
│   └── theme: ThemeMode (enum)
└── groups: [EnvGroup]
    └── EnvGroup (可多个)
        ├── id: UUID
        ├── name: String
        ├── description: String
        ├── isEnabled: Bool
        ├── order: Int
        ├── createdAt: Date
        ├── updatedAt: Date
        └── variables: [EnvVariable]
            └── EnvVariable (可多个)
                ├── id: UUID
                ├── key: String
                ├── value: String
                ├── isSensitive: Bool
                ├── createdAt: Date
                └── updatedAt: Date
```

### 3.3 JSON 存储格式示例

```json
{
  "version": "1.0",
  "lastSavedAt": "2026-02-08T10:30:00Z",
  "settings": {
    "shellType": "zsh",
    "configFilePath": "/Users/username/.zshrc",
    "autoBackup": true,
    "maxBackupCount": 10,
    "theme": "auto",
    "enableConflictDetection": true,
    "enableRegexSearch": false,
    "exportIncludesDisabledGroups": false
  },
  "groups": [
    {
      "id": "550e8400-e29b-41d4-a716-446655440000",
      "name": "前端开发",
      "description": "Node.js 前端项目环境",
      "isEnabled": true,
      "order": 0,
      "createdAt": "2026-02-01T12:00:00Z",
      "updatedAt": "2026-02-08T10:00:00Z",
      "variables": [
        {
          "id": "660e8400-e29b-41d4-a716-446655440001",
          "key": "NODE_ENV",
          "value": "development",
          "isSensitive": false,
          "createdAt": "2026-02-01T12:00:00Z",
          "updatedAt": "2026-02-01T12:00:00Z"
        },
        {
          "id": "770e8400-e29b-41d4-a716-446655440002",
          "key": "API_KEY",
          "value": "sk-xxxxxxxxxxxxx",
          "isSensitive": true,
          "createdAt": "2026-02-05T14:30:00Z",
          "updatedAt": "2026-02-05T14:30:00Z"
        }
      ]
    }
  ]
}
```

---

## 4. 核心模块设计

### 4.1 DataStore（数据持久化服务）

#### 4.1.1 职责

- 读取和写入 JSON 数据文件
- 保证数据一致性和原子性
- 提供线程安全的访问

#### 4.1.2 接口设计

```swift
import Foundation

final class DataStore {
    // MARK: - Singleton
    static let shared = DataStore()

    // MARK: - Properties
    private let fileURL: URL
    private let fileManager = FileManager.default
    private let queue = DispatchQueue(label: "com.ienvs.datastore", qos: .userInitiated)

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
    func load() throws -> AppData {
        try queue.sync {
            guard fileManager.fileExists(atPath: fileURL.path) else {
                // 首次启动，返回默认数据
                let defaultData = AppData.default
                try save(defaultData)
                return defaultData
            }

            let data = try Data(contentsOf: fileURL)
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601

            return try decoder.decode(AppData.self, from: data)
        }
    }

    /// 保存应用数据
    func save(_ appData: AppData) throws {
        try queue.sync {
            var updatedData = appData
            updatedData.lastSavedAt = Date()

            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .iso8601
            encoder.outputFormatting = [.prettyPrinted, .sortedKeys]

            let data = try encoder.encode(updatedData)

            // 原子写入（先写临时文件，再替换）
            let tempURL = fileURL.deletingLastPathComponent()
                .appendingPathComponent("data.tmp.json")
            try data.write(to: tempURL)
            try fileManager.moveItem(at: tempURL, to: fileURL)
        }
    }

    /// 备份当前数据
    func backup() throws {
        let backupDir = fileURL.deletingLastPathComponent()
            .appendingPathComponent("backups", isDirectory: true)
        try fileManager.createDirectory(at: backupDir, withIntermediateDirectories: true)

        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyyMMdd_HHmmss"
        let timestamp = dateFormatter.string(from: Date())
        let backupURL = backupDir.appendingPathComponent("data_\(timestamp).json")

        try fileManager.copyItem(at: fileURL, to: backupURL)
    }
}
```

#### 4.1.3 存储路径

```
~/Library/Application Support/iEnvs/
├── data.json              # 主数据文件
├── backups/               # 数据备份目录
│   ├── data_20260208_100000.json
│   └── data_20260208_150000.json
└── logs/                  # 日志目录（未来扩展）
```

#### 4.1.4 错误处理

| 错误类型 | 处理策略 |
|---------|---------|
| 文件不存在 | 创建默认数据 |
| JSON 解析失败 | 尝试恢复备份，否则使用默认数据 |
| 写入权限不足 | 弹出错误提示，要求用户检查权限 |
| 磁盘空间不足 | 提示清理空间，禁止写入 |

### 4.2 ShellConfigManager（Shell 配置文件管理）

#### 4.2.1 职责

这是 iEnvs 最核心的模块，负责：

- 检测当前 Shell 类型和配置文件路径
- 读取和解析 Shell 配置文件
- 在配置文件中标记和管理 iEnvs 控制的区域
- 根据启用的分组生成 export 语句
- 保证配置文件写入的安全性（备份、回滚）

#### 4.2.2 配置文件标记格式

iEnvs 在配置文件中使用特殊注释标记管理区域：

```bash
# ========== iEnvs Managed Variables ==========
# 警告：请勿手动编辑此区域
# 由 iEnvs 自动管理 - https://github.com/yourname/ienvs
# 最后更新：2026-02-08 10:30:00

# [iEnvs:550e8400-e29b-41d4-a716-446655440000] START - 前端开发
export NODE_ENV="development"
export API_KEY="sk-xxxxxxxxxxxxx"
export PATH="/usr/local/bin/node:$PATH"
# [iEnvs:550e8400-e29b-41d4-a716-446655440000] END - 前端开发

# [iEnvs:660e8400-e29b-41d4-a716-446655440001] START - AWS 生产环境
export AWS_REGION="us-west-2"
export AWS_ACCESS_KEY_ID="AKIAXXXXXXXX"
# [iEnvs:660e8400-e29b-41d4-a716-446655440001] END - AWS 生产环境

# ========== End of iEnvs Managed Variables ==========
```

**标记说明：**

- 整体区域：`========== iEnvs Managed Variables ==========` 包裹
- 每个分组：`[iEnvs:{GROUP_ID}] START/END` 标记
- 分组 ID 使用 UUID，避免名称冲突
- 分组名称作为注释，便于人类阅读

#### 4.2.3 接口设计

```swift
import Foundation

final class ShellConfigManager {
    // MARK: - Constants
    private enum Marker {
        static let sectionStart = "# ========== iEnvs Managed Variables =========="
        static let sectionEnd = "# ========== End of iEnvs Managed Variables =========="
        static let warning = "# 警告：请勿手动编辑此区域"
        static let generator = "# 由 iEnvs 自动管理 - https://github.com/yourname/ienvs"

        static func groupStart(id: UUID, name: String) -> String {
            "# [iEnvs:\(id.uuidString)] START - \(name)"
        }

        static func groupEnd(id: UUID, name: String) -> String {
            "# [iEnvs:\(id.uuidString)] END - \(name)"
        }
    }

    // MARK: - Properties
    private let backupManager: BackupManager
    private let fileManager = FileManager.default

    // MARK: - Initialization
    init(backupManager: BackupManager = .shared) {
        self.backupManager = backupManager
    }

    // MARK: - Public Methods

    /// 同步分组到 Shell 配置文件
    func syncToShellConfig(
        groups: [EnvGroup],
        configPath: String,
        autoBackup: Bool
    ) throws {
        // 1. 备份原文件
        if autoBackup {
            try backupManager.backupFile(at: configPath)
        }

        // 2. 读取配置文件
        let originalContent = try String(contentsOfFile: configPath, encoding: .utf8)

        // 3. 生成新的 iEnvs 管理区域
        let managedSection = try generateManagedSection(from: groups)

        // 4. 替换或插入管理区域
        let newContent = try replaceManagedSection(
            in: originalContent,
            with: managedSection
        )

        // 5. 写回文件
        try newContent.write(toFile: configPath, atomically: true, encoding: .utf8)
    }

    /// 从配置文件中移除 iEnvs 管理区域
    func removeManagedSection(configPath: String, autoBackup: Bool) throws {
        if autoBackup {
            try backupManager.backupFile(at: configPath)
        }

        let originalContent = try String(contentsOfFile: configPath, encoding: .utf8)
        let newContent = try replaceManagedSection(in: originalContent, with: "")

        try newContent.write(toFile: configPath, atomically: true, encoding: .utf8)
    }

    // MARK: - Private Methods

    /// 生成 iEnvs 管理区域内容
    private func generateManagedSection(from groups: [EnvGroup]) throws -> String {
        let enabledGroups = groups.filter { $0.isEnabled }.sorted { $0.order < $1.order }

        guard !enabledGroups.isEmpty else {
            return "" // 没有启用的分组，移除整个管理区域
        }

        var lines: [String] = []

        // 区域头部
        lines.append(Marker.sectionStart)
        lines.append(Marker.warning)
        lines.append(Marker.generator)

        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        lines.append("# 最后更新：\(dateFormatter.string(from: Date()))")
        lines.append("")

        // 每个分组
        for group in enabledGroups {
            lines.append(Marker.groupStart(id: group.id, name: group.name))

            for variable in group.variables {
                let exportLine = generateExportLine(key: variable.key, value: variable.value)
                lines.append(exportLine)
            }

            lines.append(Marker.groupEnd(id: group.id, name: group.name))
            lines.append("")
        }

        // 区域尾部
        lines.append(Marker.sectionEnd)

        return lines.joined(separator: "\n")
    }

    /// 生成 export 语句
    private func generateExportLine(key: String, value: String) -> String {
        // 判断值是否需要引号
        let needsQuotes = value.contains(" ")
            || value.contains("$")
            || value.contains("*")
            || value.contains("?")
            || value.contains("~")

        if needsQuotes {
            // 使用双引号包裹，并转义内部的双引号和反斜杠
            let escapedValue = value
                .replacingOccurrences(of: "\\", with: "\\\\")
                .replacingOccurrences(of: "\"", with: "\\\"")
            return "export \(key)=\"\(escapedValue)\""
        } else {
            return "export \(key)=\(value)"
        }
    }

    /// 替换配置文件中的 iEnvs 管理区域
    private func replaceManagedSection(
        in content: String,
        with newSection: String
    ) throws -> String {
        let lines = content.components(separatedBy: .newlines)
        var result: [String] = []
        var inManagedSection = false
        var foundSection = false

        for line in lines {
            if line.contains(Marker.sectionStart) {
                inManagedSection = true
                foundSection = true

                // 插入新的管理区域
                if !newSection.isEmpty {
                    result.append(newSection)
                }

                continue
            }

            if line.contains(Marker.sectionEnd) {
                inManagedSection = false
                continue
            }

            if !inManagedSection {
                result.append(line)
            }
        }

        // 如果没有找到管理区域，在文件末尾添加
        if !foundSection && !newSection.isEmpty {
            result.append("") // 空行
            result.append(newSection)
        }

        return result.joined(separator: "\n")
    }
}
```

#### 4.2.4 同步算法流程图

```
┌────────────────────────────────────────┐
│  syncToShellConfig() 调用             │
└───────────────┬────────────────────────┘
                │
                ▼
┌────────────────────────────────────────┐
│  1. 备份原配置文件                     │
│     ~/.zshrc → ~/.zshrc.ienvs.backup   │
└───────────────┬────────────────────────┘
                │
                ▼
┌────────────────────────────────────────┐
│  2. 读取配置文件全文                   │
└───────────────┬────────────────────────┘
                │
                ▼
┌────────────────────────────────────────┐
│  3. 过滤出启用的分组                   │
│     groups.filter { $0.isEnabled }     │
└───────────────┬────────────────────────┘
                │
                ▼
┌────────────────────────────────────────┐
│  4. 按 order 排序                      │
└───────────────┬────────────────────────┘
                │
                ▼
┌────────────────────────────────────────┐
│  5. 生成每个分组的 export 语句块       │
│     ┌─────────────────────────────┐   │
│     │ # [iEnvs:UUID] START        │   │
│     │ export KEY1=VALUE1          │   │
│     │ export KEY2=VALUE2          │   │
│     │ # [iEnvs:UUID] END          │   │
│     └─────────────────────────────┘   │
└───────────────┬────────────────────────┘
                │
                ▼
┌────────────────────────────────────────┐
│  6. 查找原文件中的 iEnvs 管理区域      │
│     (从 START 到 END 标记)             │
└───────────────┬────────────────────────┘
                │
                ▼
        ┌───────┴───────┐
        │ 找到管理区域？ │
        └───────┬───────┘
          Yes   │   No
    ┌───────────┴───────────┐
    ▼                       ▼
┌──────────┐         ┌─────────────┐
│ 替换区域 │         │ 末尾添加区域│
└────┬─────┘         └──────┬──────┘
     │                      │
     └──────────┬───────────┘
                ▼
┌────────────────────────────────────────┐
│  7. 写回配置文件（原子写入）           │
└───────────────┬────────────────────────┘
                │
                ▼
┌────────────────────────────────────────┐
│  8. 成功完成 ✓                         │
└────────────────────────────────────────┘
```

#### 4.2.5 值转义规则

| 场景 | 示例 | 转义后 |
|------|------|--------|
| 普通值 | `development` | `export KEY=development` |
| 包含空格 | `My App` | `export KEY="My App"` |
| 包含变量引用 | `$HOME/bin` | `export KEY="$HOME/bin"` |
| 包含双引号 | `He said "Hi"` | `export KEY="He said \"Hi\""` |
| 包含反斜杠 | `C:\Windows` | `export KEY="C:\\Windows"` |

### 4.3 BackupManager（备份管理服务）

#### 4.3.1 职责

- 在修改 Shell 配置文件前自动备份
- 管理备份文件的生命周期（清理旧备份）
- 提供恢复备份的能力

#### 4.3.2 接口设计

```swift
import Foundation

final class BackupManager {
    // MARK: - Singleton
    static let shared = BackupManager()

    // MARK: - Properties
    private let fileManager = FileManager.default
    private let backupDir: URL

    // MARK: - Initialization
    private init() {
        let appSupportDir = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        self.backupDir = appSupportDir
            .appendingPathComponent("iEnvs/backups", isDirectory: true)

        try? fileManager.createDirectory(at: backupDir, withIntermediateDirectories: true)
    }

    // MARK: - Public Methods

    /// 备份指定文件
    func backupFile(at path: String) throws {
        let sourceURL = URL(fileURLWithPath: path)

        guard fileManager.fileExists(atPath: path) else {
            throw BackupError.sourceFileNotFound
        }

        let fileName = sourceURL.lastPathComponent
        let timestamp = DateFormatter.backupTimestamp.string(from: Date())
        let backupFileName = "\(fileName).\(timestamp).bak"
        let backupURL = backupDir.appendingPathComponent(backupFileName)

        try fileManager.copyItem(at: sourceURL, to: backupURL)
    }

    /// 获取所有备份文件
    func listBackups(for configFileName: String) throws -> [BackupFile] {
        let contents = try fileManager.contentsOfDirectory(
            at: backupDir,
            includingPropertiesForKeys: [.creationDateKey, .fileSizeKey]
        )

        let backups = contents
            .filter { $0.lastPathComponent.starts(with: configFileName) }
            .compactMap { url -> BackupFile? in
                guard let attributes = try? fileManager.attributesOfItem(atPath: url.path),
                      let creationDate = attributes[.creationDate] as? Date,
                      let fileSize = attributes[.size] as? Int64 else {
                    return nil
                }

                return BackupFile(
                    url: url,
                    createdAt: creationDate,
                    size: fileSize
                )
            }
            .sorted { $0.createdAt > $1.createdAt } // 最新的在前

        return backups
    }

    /// 恢复备份
    func restoreBackup(_ backup: BackupFile, to targetPath: String) throws {
        let targetURL = URL(fileURLWithPath: targetPath)

        // 先备份当前文件
        if fileManager.fileExists(atPath: targetPath) {
            try backupFile(at: targetPath)
        }

        // 替换为备份文件
        try fileManager.removeItem(at: targetURL)
        try fileManager.copyItem(at: backup.url, to: targetURL)
    }

    /// 清理旧备份（保留最新的 N 个）
    func cleanupOldBackups(for configFileName: String, keepCount: Int) throws {
        let backups = try listBackups(for: configFileName)

        guard backups.count > keepCount else { return }

        let toDelete = backups.dropFirst(keepCount)
        for backup in toDelete {
            try fileManager.removeItem(at: backup.url)
        }
    }
}

// MARK: - Supporting Types
struct BackupFile: Identifiable {
    let url: URL
    let createdAt: Date
    let size: Int64

    var id: URL { url }

    var displayName: String {
        url.lastPathComponent
    }

    var formattedSize: String {
        ByteCountFormatter.string(fromByteCount: size, countStyle: .file)
    }
}

enum BackupError: LocalizedError {
    case sourceFileNotFound
    case backupDirectoryNotAccessible

    var errorDescription: String? {
        switch self {
        case .sourceFileNotFound:
            return "源文件不存在"
        case .backupDirectoryNotAccessible:
            return "无法访问备份目录"
        }
    }
}

// MARK: - DateFormatter Extension
extension DateFormatter {
    static let backupTimestamp: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyyMMdd_HHmmss"
        return formatter
    }()
}
```

#### 4.3.3 备份文件命名规则

```
原文件: ~/.zshrc
备份文件: .zshrc.20260208_103000.bak
          ^^^^^^ ^^^^^^^^^^^^^^^^
          原名称  时间戳
```

#### 4.3.4 自动清理策略

- 每次创建备份后，检查备份数量
- 如果超过 `maxBackupCount`（默认 10），删除最旧的备份
- 按照创建时间排序，保留最新的 N 个

### 4.4 ConflictDetector（冲突检测服务）

#### 4.4.1 职责

- 检测同一分组内的变量名冲突
- 检测跨分组的变量名冲突
- 根据分组顺序确定最终生效的值

#### 4.4.2 接口设计

```swift
import Foundation

final class ConflictDetector {
    /// 检测所有冲突
    func detectConflicts(in groups: [EnvGroup]) -> [Conflict] {
        let enabledGroups = groups.filter { $0.isEnabled }
        var conflicts: [Conflict] = []
        var keyToGroups: [String: [EnvGroup]] = [:]

        // 收集所有变量名及其所属分组
        for group in enabledGroups {
            for variable in group.variables {
                keyToGroups[variable.key, default: []].append(group)
            }
        }

        // 找出重复的变量名
        for (key, groups) in keyToGroups where groups.count > 1 {
            let sortedGroups = groups.sorted { $0.order < $1.order }
            let effectiveGroup = sortedGroups.last! // 最后一个分组生效

            conflicts.append(Conflict(
                key: key,
                groups: sortedGroups,
                effectiveGroup: effectiveGroup
            ))
        }

        return conflicts
    }

    /// 检查特定变量名在分组内是否重复
    func isDuplicateInGroup(_ key: String, in group: EnvGroup, excluding variableID: UUID? = nil) -> Bool {
        group.variables.contains { variable in
            variable.key == key && variable.id != variableID
        }
    }
}

// MARK: - Supporting Types
struct Conflict: Identifiable {
    let id = UUID()
    let key: String
    let groups: [EnvGroup]
    let effectiveGroup: EnvGroup

    var affectedGroupIDs: Set<UUID> {
        Set(groups.map { $0.id })
    }

    var description: String {
        let groupNames = groups.map { $0.name }.joined(separator: "、")
        return "变量 \(key) 在以下分组中重复：\(groupNames)"
    }

    var effectiveValue: String? {
        effectiveGroup.variables.first { $0.key == key }?.value
    }
}
```

### 4.5 ImportExportManager（导入导出服务）

#### 4.5.1 职责

- 导出分组为 JSON 文件
- 导出分组为 Shell 脚本
- 从 JSON 文件导入分组
- 处理导入时的名称冲突

#### 4.5.2 导出格式定义

```swift
import Foundation

struct ExportData: Codable {
    let version: String
    let exportDate: Date
    let groups: [EnvGroup]

    init(groups: [EnvGroup]) {
        self.version = "1.0"
        self.exportDate = Date()
        self.groups = groups
    }
}
```

#### 4.5.3 接口设计

```swift
import Foundation
import AppKit

final class ImportExportManager {
    // MARK: - Export

    /// 导出为 JSON 文件
    func exportToJSON(groups: [EnvGroup], includeDisabled: Bool) throws -> URL {
        let groupsToExport = includeDisabled ? groups : groups.filter { $0.isEnabled }
        let exportData = ExportData(groups: groupsToExport)

        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]

        let data = try encoder.encode(exportData)

        // 弹出保存对话框
        let savePanel = NSSavePanel()
        savePanel.allowedContentTypes = [.json]
        savePanel.nameFieldStringValue = "ienvs-export-\(Date.filenameSafeString).json"

        guard savePanel.runModal() == .OK, let url = savePanel.url else {
            throw ExportError.userCancelled
        }

        try data.write(to: url)
        return url
    }

    /// 导出为 Shell 脚本
    func exportToShellScript(group: EnvGroup) throws -> URL {
        var lines: [String] = []

        // 头部
        lines.append("#!/bin/bash")
        lines.append("# iEnvs Export: \(group.name)")
        if !group.description.isEmpty {
            lines.append("# Description: \(group.description)")
        }
        lines.append("# Generated: \(Date.readableString)")
        lines.append("")

        // Export 语句
        for variable in group.variables {
            let exportLine = generateExportLine(key: variable.key, value: variable.value)
            lines.append(exportLine)
        }

        let content = lines.joined(separator: "\n")

        // 保存对话框
        let savePanel = NSSavePanel()
        savePanel.allowedContentTypes = [.shellScript]
        savePanel.nameFieldStringValue = "\(group.name).sh"

        guard savePanel.runModal() == .OK, let url = savePanel.url else {
            throw ExportError.userCancelled
        }

        try content.write(to: url, atomically: true, encoding: .utf8)

        // 添加可执行权限
        try FileManager.default.setAttributes(
            [.posixPermissions: 0o755],
            ofItemAtPath: url.path
        )

        return url
    }

    // MARK: - Import

    /// 从 JSON 文件导入
    func importFromJSON(existingGroups: [EnvGroup]) throws -> [EnvGroup] {
        // 打开文件对话框
        let openPanel = NSOpenPanel()
        openPanel.allowedContentTypes = [.json]
        openPanel.allowsMultipleSelection = false

        guard openPanel.runModal() == .OK, let url = openPanel.url else {
            throw ImportError.userCancelled
        }

        let data = try Data(contentsOf: url)
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601

        let exportData = try decoder.decode(ExportData.self, from: data)

        // 版本兼容性检查
        guard exportData.version == "1.0" else {
            throw ImportError.incompatibleVersion(exportData.version)
        }

        // 处理名称冲突
        var importedGroups: [EnvGroup] = []
        let existingNames = Set(existingGroups.map { $0.name })

        for var group in exportData.groups {
            if existingNames.contains(group.name) {
                // 弹出对话框询问用户
                let action = try askUserForConflictResolution(groupName: group.name)

                switch action {
                case .skip:
                    continue
                case .rename:
                    group.name = generateUniqueName(baseName: group.name, existingNames: existingNames)
                case .overwrite:
                    // 移除旧分组
                    if let index = existingGroups.firstIndex(where: { $0.name == group.name }) {
                        existingGroups.remove(at: index)
                    }
                }
            }

            // 重新生成 ID 和时间戳
            group = EnvGroup(
                name: group.name,
                description: group.description,
                isEnabled: false, // 导入后默认禁用
                variables: group.variables,
                order: existingGroups.count + importedGroups.count
            )

            importedGroups.append(group)
        }

        return importedGroups
    }

    // MARK: - Private Methods

    private func generateExportLine(key: String, value: String) -> String {
        // 与 ShellConfigManager 的逻辑一致
        let needsQuotes = value.contains(" ") || value.contains("$")

        if needsQuotes {
            let escapedValue = value
                .replacingOccurrences(of: "\\", with: "\\\\")
                .replacingOccurrences(of: "\"", with: "\\\"")
            return "export \(key)=\"\(escapedValue)\""
        } else {
            return "export \(key)=\(value)"
        }
    }

    private func generateUniqueName(baseName: String, existingNames: Set<String>) -> String {
        var counter = 1
        var newName = "\(baseName)-导入"

        while existingNames.contains(newName) {
            counter += 1
            newName = "\(baseName)-导入\(counter)"
        }

        return newName
    }

    private func askUserForConflictResolution(groupName: String) throws -> ConflictResolution {
        let alert = NSAlert()
        alert.messageText = "分组名称冲突"
        alert.informativeText = "已存在名为 "\(groupName)" 的分组，请选择操作："
        alert.addButton(withTitle: "跳过")
        alert.addButton(withTitle: "重命名")
        alert.addButton(withTitle: "覆盖")

        let response = alert.runModal()

        switch response {
        case .alertFirstButtonReturn:
            return .skip
        case .alertSecondButtonReturn:
            return .rename
        case .alertThirdButtonReturn:
            return .overwrite
        default:
            throw ImportError.userCancelled
        }
    }
}

// MARK: - Supporting Types
enum ConflictResolution {
    case skip
    case rename
    case overwrite
}

enum ExportError: LocalizedError {
    case userCancelled

    var errorDescription: String? {
        "用户取消了操作"
    }
}

enum ImportError: LocalizedError {
    case userCancelled
    case incompatibleVersion(String)
    case invalidFormat

    var errorDescription: String? {
        switch self {
        case .userCancelled:
            return "用户取消了导入"
        case .incompatibleVersion(let version):
            return "不兼容的文件版本：\(version)"
        case .invalidFormat:
            return "无效的 JSON 格式"
        }
    }
}

// MARK: - Date Extensions
extension Date {
    static var filenameSafeString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyyMMdd"
        return formatter.string(from: Date())
    }

    static var readableString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        return formatter.string(from: Date())
    }
}
```

---

## 5. 视图层设计

### 5.1 MainView（主窗口）

#### 5.1.1 布局结构

```swift
import SwiftUI

struct MainView: View {
    @StateObject private var viewModel = EnvGroupViewModel()
    @State private var selectedGroupID: UUID?
    @State private var searchText = ""

    var body: some View {
        NavigationSplitView(
            columnVisibility: .constant(.all)
        ) {
            // 左侧 Sidebar
            SidebarView(
                viewModel: viewModel,
                selectedGroupID: $selectedGroupID,
                searchText: $searchText
            )
            .navigationSplitViewColumnWidth(min: 200, ideal: 250, max: 350)
        } detail: {
            // 右侧 Detail
            if let groupID = selectedGroupID,
               let group = viewModel.groups.first(where: { $0.id == groupID }) {
                DetailView(
                    group: group,
                    viewModel: viewModel
                )
            } else {
                EmptyStateView()
            }
        }
        .toolbar {
            ToolbarView(viewModel: viewModel)
        }
        .onAppear {
            viewModel.loadData()
        }
    }
}
```

### 5.2 SidebarView（左侧分组列表）

```swift
import SwiftUI

struct SidebarView: View {
    @ObservedObject var viewModel: EnvGroupViewModel
    @Binding var selectedGroupID: UUID?
    @Binding var searchText: String

    var filteredGroups: [EnvGroup] {
        if searchText.isEmpty {
            return viewModel.groups
        } else {
            return viewModel.groups.filter { group in
                group.name.localizedCaseInsensitiveContains(searchText)
                || group.variables.contains { variable in
                    variable.key.localizedCaseInsensitiveContains(searchText)
                    || variable.value.localizedCaseInsensitiveContains(searchText)
                }
            }
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            // 搜索框
            SearchBar(text: $searchText)
                .padding()

            // 分组列表
            List(selection: $selectedGroupID) {
                ForEach(filteredGroups) { group in
                    GroupRowView(
                        group: group,
                        viewModel: viewModel
                    )
                    .tag(group.id)
                    .contextMenu {
                        GroupContextMenu(group: group, viewModel: viewModel)
                    }
                }
                .onMove { source, destination in
                    viewModel.moveGroups(from: source, to: destination)
                }
            }

            Divider()

            // 底部工具栏
            GroupToolbar(viewModel: viewModel, selectedGroupID: $selectedGroupID)
                .padding(8)
        }
        .navigationTitle("分组")
    }
}
```

### 5.3 GroupRowView（分组行）

```swift
import SwiftUI

struct GroupRowView: View {
    let group: EnvGroup
    @ObservedObject var viewModel: EnvGroupViewModel

    var hasConflicts: Bool {
        viewModel.conflicts.contains { conflict in
            conflict.affectedGroupIDs.contains(group.id)
        }
    }

    var body: some View {
        HStack(spacing: 12) {
            // 启用开关
            Toggle("", isOn: Binding(
                get: { group.isEnabled },
                set: { newValue in
                    viewModel.toggleGroup(group.id, enabled: newValue)
                }
            ))
            .toggleStyle(.switch)
            .labelsHidden()

            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(group.name)
                        .font(.headline)

                    if hasConflicts {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundStyle(.yellow)
                            .help("此分组存在变量冲突")
                    }
                }

                Text("\(group.variableCount) 个变量")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()
        }
        .padding(.vertical, 4)
    }
}
```

### 5.4 DetailView（右侧变量详情）

```swift
import SwiftUI

struct DetailView: View {
    let group: EnvGroup
    @ObservedObject var viewModel: EnvGroupViewModel
    @State private var searchText = ""
    @State private var selectedVariableIDs = Set<UUID>()
    @State private var editingVariable: EnvVariable?

    var filteredVariables: [EnvVariable] {
        if searchText.isEmpty {
            return group.variables
        } else {
            return group.variables.filter { variable in
                variable.key.localizedCaseInsensitiveContains(searchText)
                || variable.value.localizedCaseInsensitiveContains(searchText)
            }
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            // 标题栏
            HStack {
                VStack(alignment: .leading) {
                    Text(group.name)
                        .font(.title2)
                        .bold()

                    if !group.description.isEmpty {
                        Text(group.description)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }

                Spacer()

                // 工具按钮
                Button(action: { editingVariable = EnvVariable(key: "", value: "") }) {
                    Label("添加", systemImage: "plus")
                }

                Button(action: deleteSelectedVariables) {
                    Label("删除", systemImage: "minus")
                }
                .disabled(selectedVariableIDs.isEmpty)
            }
            .padding()

            Divider()

            // 搜索框
            SearchBar(text: $searchText)
                .padding(.horizontal)

            // 变量列表
            if filteredVariables.isEmpty {
                EmptyStateView()
            } else {
                Table(of: EnvVariable.self, selection: $selectedVariableIDs) {
                    TableColumn("变量名") { variable in
                        Text(variable.key)
                            .font(.system(.body, design: .monospaced))
                    }
                    .width(ideal: 200)

                    TableColumn("值") { variable in
                        if variable.isSensitive {
                            Text("••••••••")
                                .foregroundStyle(.secondary)
                        } else {
                            Text(variable.value)
                                .font(.system(.body, design: .monospaced))
                        }
                    }
                } rows: {
                    ForEach(filteredVariables) { variable in
                        TableRow(variable)
                            .contextMenu {
                                VariableContextMenu(
                                    variable: variable,
                                    group: group,
                                    viewModel: viewModel
                                )
                            }
                    }
                }
            }
        }
        .sheet(item: $editingVariable) { variable in
            VariableEditView(
                variable: variable,
                group: group,
                viewModel: viewModel,
                isPresented: $editingVariable
            )
        }
    }

    private func deleteSelectedVariables() {
        for variableID in selectedVariableIDs {
            viewModel.deleteVariable(variableID, from: group.id)
        }
        selectedVariableIDs.removeAll()
    }
}
```

### 5.5 SettingsView（设置面板）

```swift
import SwiftUI

struct SettingsView: View {
    @StateObject private var viewModel = SettingsViewModel()

    var body: some View {
        TabView {
            GeneralSettings(viewModel: viewModel)
                .tabItem {
                    Label("通用", systemImage: "gearshape")
                }

            ShellSettings(viewModel: viewModel)
                .tabItem {
                    Label("Shell", systemImage: "terminal")
                }

            BackupSettings(viewModel: viewModel)
                .tabItem {
                    Label("备份", systemImage: "clock.arrow.circlepath")
                }
        }
        .frame(width: 600, height: 400)
    }
}
```

---

## 6. 视图模型设计

### 6.1 EnvGroupViewModel

```swift
import Foundation
import Combine

final class EnvGroupViewModel: ObservableObject {
    // MARK: - Published Properties
    @Published var groups: [EnvGroup] = []
    @Published var conflicts: [Conflict] = []
    @Published var isLoading = false
    @Published var errorMessage: String?

    // MARK: - Dependencies
    private let dataStore: DataStore
    private let shellConfigManager: ShellConfigManager
    private let conflictDetector: ConflictDetector
    private var cancellables = Set<AnyCancellable>()

    // MARK: - Initialization
    init(
        dataStore: DataStore = .shared,
        shellConfigManager: ShellConfigManager = ShellConfigManager(),
        conflictDetector: ConflictDetector = ConflictDetector()
    ) {
        self.dataStore = dataStore
        self.shellConfigManager = shellConfigManager
        self.conflictDetector = conflictDetector

        // 监听 groups 变化，自动检测冲突
        $groups
            .sink { [weak self] groups in
                self?.detectConflicts()
            }
            .store(in: &cancellables)
    }

    // MARK: - Data Loading
    func loadData() {
        isLoading = true

        do {
            let appData = try dataStore.load()
            groups = appData.groups.sorted { $0.order < $1.order }
            isLoading = false
        } catch {
            errorMessage = "加载数据失败：\(error.localizedDescription)"
            isLoading = false
        }
    }

    // MARK: - Group Operations
    func addGroup(name: String, description: String) {
        let newGroup = EnvGroup(
            name: name,
            description: description,
            order: groups.count
        )

        groups.append(newGroup)
        saveData()
    }

    func deleteGroup(_ groupID: UUID) {
        guard let index = groups.firstIndex(where: { $0.id == groupID }) else { return }
        groups.remove(at: index)

        // 重新排序
        reorderGroups()
        saveData()
    }

    func toggleGroup(_ groupID: UUID, enabled: Bool) {
        guard let index = groups.firstIndex(where: { $0.id == groupID }) else { return }
        groups[index].isEnabled = enabled
        groups[index].updatedAt = Date()

        saveData()
        syncToShell()
    }

    func moveGroups(from source: IndexSet, to destination: Int) {
        groups.move(fromOffsets: source, toOffset: destination)
        reorderGroups()
        saveData()
    }

    // MARK: - Variable Operations
    func addVariable(_ variable: EnvVariable, to groupID: UUID) {
        guard let index = groups.firstIndex(where: { $0.id == groupID }) else { return }
        groups[index].variables.append(variable)
        groups[index].updatedAt = Date()

        saveData()

        if groups[index].isEnabled {
            syncToShell()
        }
    }

    func deleteVariable(_ variableID: UUID, from groupID: UUID) {
        guard let groupIndex = groups.firstIndex(where: { $0.id == groupID }),
              let varIndex = groups[groupIndex].variables.firstIndex(where: { $0.id == variableID }) else {
            return
        }

        groups[groupIndex].variables.remove(at: varIndex)
        groups[groupIndex].updatedAt = Date()

        saveData()

        if groups[groupIndex].isEnabled {
            syncToShell()
        }
    }

    // MARK: - Conflict Detection
    private func detectConflicts() {
        conflicts = conflictDetector.detectConflicts(in: groups)
    }

    // MARK: - Shell Sync
    private func syncToShell() {
        do {
            let settings = try dataStore.load().settings
            try shellConfigManager.syncToShellConfig(
                groups: groups,
                configPath: settings.configFilePath,
                autoBackup: settings.autoBackup
            )

            // 显示通知
            showNotification(
                title: "配置已更新",
                message: "请运行 `source ~/.zshrc` 使其生效"
            )
        } catch {
            errorMessage = "同步到 Shell 失败：\(error.localizedDescription)"
        }
    }

    // MARK: - Data Persistence
    private func saveData() {
        do {
            var appData = try dataStore.load()
            appData.groups = groups
            try dataStore.save(appData)
        } catch {
            errorMessage = "保存数据失败：\(error.localizedDescription)"
        }
    }

    private func reorderGroups() {
        for (index, _) in groups.enumerated() {
            groups[index].order = index
        }
    }

    private func showNotification(title: String, message: String) {
        // TODO: 使用 UNUserNotificationCenter 显示通知
    }
}
```

---

## 7. 关键流程设计

### 7.1 启用/禁用分组流程

```
用户操作
   │
   ├─> 点击分组开关
   │
   ▼
GroupRowView
   │
   ├─> Toggle.onChange
   │
   ▼
EnvGroupViewModel.toggleGroup(groupID, enabled)
   │
   ├─> 1. 更新 group.isEnabled
   ├─> 2. 更新 group.updatedAt
   ├─> 3. saveData()  // 保存到 JSON
   │
   ▼
syncToShell()
   │
   ├─> 加载 settings（获取 configFilePath、autoBackup）
   │
   ▼
ShellConfigManager.syncToShellConfig()
   │
   ├─> 1. backupManager.backupFile()  // 备份 .zshrc
   ├─> 2. 读取配置文件全文
   ├─> 3. 过滤启用的分组
   ├─> 4. 生成 export 语句块
   ├─> 5. 替换管理区域
   ├─> 6. 写回文件
   │
   ▼
显示通知
   │
   └─> "配置已更新，请运行 source ~/.zshrc"
```

### 7.2 冲突检测流程

```
触发条件：
  - groups 数组发生变化
  - ViewModel 初始化时

EnvGroupViewModel.$groups.sink
   │
   ▼
detectConflicts()
   │
   ▼
ConflictDetector.detectConflicts(in: groups)
   │
   ├─> 1. 过滤出启用的分组
   ├─> 2. 收集所有变量名及其所属分组
   │      keyToGroups: [String: [EnvGroup]]
   ├─> 3. 找出重复的变量名（groups.count > 1）
   ├─> 4. 根据 order 排序，确定生效分组
   │
   ▼
返回 [Conflict]
   │
   ├─> Conflict.affectedGroupIDs
   ├─> Conflict.description
   ├─> Conflict.effectiveGroup
   │
   ▼
UI 渲染
   │
   ├─> GroupRowView: 显示警告图标
   └─> VariableRowView: 高亮冲突变量
```

### 7.3 导入分组流程

```
用户操作
   │
   ├─> 点击 "导入" 按钮
   │
   ▼
ImportExportManager.importFromJSON()
   │
   ├─> 1. NSOpenPanel 选择 JSON 文件
   ├─> 2. 读取文件内容
   ├─> 3. JSONDecoder 解码
   ├─> 4. 版本兼容性检查
   │
   ▼
处理名称冲突
   │
   ├─> existingNames.contains(group.name)?
   │
   │   Yes
   │    │
   │    ├─> 弹出 NSAlert 询问用户
   │    │
   │    ├─> "跳过" → continue
   │    ├─> "重命名" → generateUniqueName()
   │    └─> "覆盖" → 删除旧分组
   │
   ▼
生成新的分组
   │
   ├─> 重新生成 ID
   ├─> isEnabled = false（默认禁用）
   ├─> order = existingGroups.count + importedGroups.count
   │
   ▼
返回 [EnvGroup]
   │
   ▼
EnvGroupViewModel
   │
   ├─> groups.append(contentsOf: importedGroups)
   ├─> saveData()
   │
   ▼
完成
```

---

## 8. 错误处理策略

### 8.1 错误分类

| 错误类型 | 处理策略 | 用户提示 |
|---------|---------|---------|
| **文件读写失败** | 记录日志，弹出 Alert | "无法读取配置文件，请检查权限" |
| **权限不足** | 弹出 Alert，提供 "在 Finder 中显示" | "无法写入 ~/.zshrc，请检查文件权限" |
| **JSON 解析失败** | 尝试恢复备份，否则使用默认数据 | "数据文件损坏，已恢复默认设置" |
| **备份失败** | 记录警告日志，继续执行 | 后台记录，不阻塞主流程 |
| **配置文件语法错误** | 回滚到备份 | "配置文件写入失败，已恢复备份" |
| **磁盘空间不足** | 禁止写入，弹出错误 | "磁盘空间不足，请清理后重试" |

### 8.2 错误恢复机制

```swift
enum AppError: LocalizedError {
    case dataLoadFailed(Error)
    case dataSaveFailed(Error)
    case shellSyncFailed(Error)
    case permissionDenied(String)
    case backupFailed(Error)

    var errorDescription: String? {
        switch self {
        case .dataLoadFailed(let error):
            return "加载数据失败：\(error.localizedDescription)"
        case .dataSaveFailed(let error):
            return "保存数据失败：\(error.localizedDescription)"
        case .shellSyncFailed(let error):
            return "同步到 Shell 失败：\(error.localizedDescription)"
        case .permissionDenied(let path):
            return "无法访问文件：\(path)"
        case .backupFailed(let error):
            return "备份失败：\(error.localizedDescription)"
        }
    }

    var recoverySuggestion: String? {
        switch self {
        case .dataLoadFailed:
            return "将尝试恢复最近的备份数据"
        case .permissionDenied:
            return "请在 Finder 中检查文件权限"
        case .shellSyncFailed:
            return "配置文件已回滚到修改前状态"
        default:
            return nil
        }
    }
}
```

### 8.3 原子性保证

**配置文件写入的原子性：**

1. 在 ShellConfigManager 中，写入前自动备份
2. 使用临时文件写入，再替换原文件
3. 如果写入失败，自动恢复备份

```swift
func syncToShellConfig(...) throws {
    // 1. 备份
    let backupURL = try backupManager.backupFile(at: configPath)

    do {
        // 2. 写入临时文件
        let tempPath = configPath + ".tmp"
        try newContent.write(toFile: tempPath, atomically: true, encoding: .utf8)

        // 3. 替换原文件
        try fileManager.removeItem(atPath: configPath)
        try fileManager.moveItem(atPath: tempPath, toPath: configPath)
    } catch {
        // 4. 失败时恢复备份
        try fileManager.copyItem(at: backupURL, to: URL(fileURLWithPath: configPath))
        throw error
    }
}
```

---

## 9. 安全性设计

### 9.1 敏感信息保护

#### 9.1.1 敏感变量标记

```swift
struct EnvVariable {
    var isSensitive: Bool  // 用户可手动标记
}
```

#### 9.1.2 UI 显示策略

- 敏感变量值在列表中显示为 `••••••••`
- 悬停时显示 "点击查看" 提示
- 点击后弹出对话框显示明文（需要二次确认）

#### 9.1.3 导出策略

```swift
func exportToJSON(..., excludeSensitive: Bool) throws -> URL {
    var groupsToExport = groups

    if excludeSensitive {
        groupsToExport = groupsToExport.map { group in
            var newGroup = group
            newGroup.variables = group.variables.filter { !$0.isSensitive }
            return newGroup
        }
    }

    // ...
}
```

### 9.2 文件权限控制

```swift
// 创建数据目录时，设置权限为仅当前用户可访问
func createDataDirectory() throws {
    let attrs: [FileAttributeKey: Any] = [
        .posixPermissions: 0o700  // rwx------
    ]

    try fileManager.createDirectory(
        at: dataDir,
        withIntermediateDirectories: true,
        attributes: attrs
    )
}
```

### 9.3 配置文件安全

- 修改前强制备份（可配置关闭，但默认开启）
- 备份文件权限继承原文件
- 写入失败自动回滚

### 9.4 数据隔离

| 数据类型 | 存储位置 | 权限 |
|---------|---------|------|
| 应用数据 | `~/Library/Application Support/iEnvs/` | 700 |
| 备份文件 | `~/Library/Application Support/iEnvs/backups/` | 700 |
| 日志文件 | `~/Library/Logs/iEnvs/` | 700 |
| Shell 配置 | `~/.zshrc` | 用户原始权限 |

---

## 10. 性能优化策略

### 10.1 数据加载优化

```swift
// 使用 lazy 延迟加载
@Published private(set) lazy var groups: [EnvGroup] = {
    loadGroupsFromDisk()
}()

// 后台线程加载
func loadData() {
    DispatchQueue.global(qos: .userInitiated).async { [weak self] in
        let appData = try? self?.dataStore.load()

        DispatchQueue.main.async {
            self?.groups = appData?.groups ?? []
        }
    }
}
```

### 10.2 搜索优化

```swift
// 使用 Combine 防抖
@Published var searchText = ""

init() {
    $searchText
        .debounce(for: .milliseconds(300), scheduler: RunLoop.main)
        .sink { [weak self] text in
            self?.performSearch(text)
        }
        .store(in: &cancellables)
}
```

### 10.3 UI 渲染优化

- 使用 `LazyVStack` / `LazyHStack` 延迟渲染
- 变量列表使用 `Table` 而不是 `List`（原生支持虚拟滚动）
- 避免在 `body` 中进行复杂计算，使用 `@State` 缓存

### 10.4 文件 I/O 优化

```swift
// 使用串行队列保证线程安全
private let ioQueue = DispatchQueue(label: "com.ienvs.io", qos: .userInitiated)

// 批量操作合并写入
func batchUpdateVariables(...) {
    ioQueue.async {
        // 批量修改
        // 最后一次性写入
        try? self.dataStore.save(appData)
    }
}
```

---

## 11. 测试策略

### 11.1 单元测试

#### 11.1.1 Model 测试

```swift
class EnvVariableTests: XCTestCase {
    func testKeyValidation() {
        XCTAssertTrue(EnvVariable(key: "VALID_KEY", value: "").isKeyValid)
        XCTAssertFalse(EnvVariable(key: "123INVALID", value: "").isKeyValid)
        XCTAssertFalse(EnvVariable(key: "INVALID-KEY", value: "").isKeyValid)
    }
}
```

#### 11.1.2 Service 测试

```swift
class ShellConfigManagerTests: XCTestCase {
    func testExportLineGeneration() {
        let manager = ShellConfigManager()

        // 普通值
        XCTAssertEqual(
            manager.generateExportLine(key: "KEY", value: "value"),
            "export KEY=value"
        )

        // 包含空格
        XCTAssertEqual(
            manager.generateExportLine(key: "KEY", value: "my value"),
            "export KEY=\"my value\""
        )
    }
}
```

### 11.2 UI 测试

```swift
class iEnvsUITests: XCTestCase {
    func testAddGroup() throws {
        let app = XCUIApplication()
        app.launch()

        app.buttons["add_group"].tap()

        let nameField = app.textFields["group_name"]
        nameField.tap()
        nameField.typeText("Test Group")

        app.buttons["save"].tap()

        XCTAssertTrue(app.staticTexts["Test Group"].exists)
    }
}
```

### 11.3 测试覆盖率目标

| 模块 | 目标覆盖率 |
|------|----------|
| Models | 90%+ |
| Services | 80%+ |
| ViewModels | 70%+ |
| Views | UI 测试覆盖 |

---

## 12. 部署与发布

### 12.1 构建配置

```
# Release 配置
- Optimization Level: -O
- Swift Compilation Mode: Whole Module
- Strip Debug Symbols: Yes
- Validate Built Product: Yes
```

### 12.2 应用签名

```bash
# 使用 Apple Developer 账号签名
codesign --force --deep --sign "Developer ID Application: Your Name" iEnvs.app

# 公证
xcrun notarytool submit iEnvs.zip --keychain-profile "AC_PASSWORD"
```

### 12.3 发布渠道

| 渠道 | 优势 | 劣势 |
|------|------|------|
| **App Store** | 可信度高，自动更新 | 审核周期长 |
| **GitHub Releases** | 快速发布，开源友好 | 需要手动更新 |
| **Homebrew Cask** | 开发者熟悉，命令行安装 | 依赖社区维护 |

---

## 13. 未来扩展

### 13.1 短期优化（v1.1 - v1.2）

- [ ] 支持变量值引用（如 `$PATH:$HOME/bin`）
- [ ] 快捷键支持（Command+N、Command+F 等）
- [ ] 撤销/重做功能（Command+Z）
- [ ] 变量修改历史记录

### 13.2 中期扩展（v2.0）

- [ ] 支持更多 Shell（Fish、Nushell）
- [ ] 分组模板库（预置常用配置）
- [ ] 环境变量值自动补全
- [ ] CLI 工具（`ienvs` 命令行版）

### 13.3 长期规划（v3.0+）

- [ ] iCloud 同步
- [ ] 团队协作功能
- [ ] Keychain 集成（加密存储敏感变量）
- [ ] Linux 版本

---

## 14. 附录

### 14.1 技术决策记录（ADR）

#### ADR-001: 为什么选择 JSON 而不是 Core Data？

**背景：** 需要持久化应用数据

**决策：** 使用 JSON 文件存储

**理由：**
- 数据量小（<10MB）
- 人类可读，便于调试
- 零依赖，简单可靠
- 易于导出/导入

**权衡：** Core Data 在大规模数据时性能更好，但 iEnvs 不需要

---

#### ADR-002: 为什么使用 UUID 标记分组？

**背景：** 需要在配置文件中标记分组

**决策：** 使用 UUID 而不是分组名称

**理由：**
- 分组名称可能被用户修改
- UUID 保证唯一性和稳定性
- 避免名称冲突

**权衡：** 配置文件中的注释略微冗长，但可读性仍然良好

---

### 14.2 参考资料

- [SwiftUI Documentation](https://developer.apple.com/documentation/swiftui)
- [macOS Human Interface Guidelines](https://developer.apple.com/design/human-interface-guidelines/macos)
- [Bash Manual](https://www.gnu.org/software/bash/manual/)
- [Zsh Documentation](https://zsh.sourceforge.io/Doc/)

---

**文档版本：** 1.0
**最后更新：** 2026-02-08
**维护者：** Architecture Team
