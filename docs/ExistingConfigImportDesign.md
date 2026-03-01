# 系统设计文档：支持读取和修改已有的环境变量及hosts配置

## 上下文

用户希望在安装iEnvs之前手动配置的环境变量和hosts能够被应用识别和管理。当前应用只管理标记区域内的配置（`========== iEnvs Managed ==========`），非管理区域的配置被忽略。

## 需求规格

1. **实时展示**：在应用中展示非iEnvs管理的环境变量和hosts
2. **修改流程**：提示用户配置将被纳入iEnvs管理 → 用户确认 → 创建iEnvs副本 → 删除原配置
3. **删除流程**：提示用户确认 → 直接从原配置文件删除
4. **双模式支持**：同时支持环境变量（~/.zshrc）和hosts（/etc/hosts）

## 技术方案

### 阶段1：环境变量 - 解析现有配置

**文件**: `iEnvs/Services/ShellConfigManager.swift`

新增方法：
```swift
/// 解析现有shell配置文件中的非管理export语句
func parseExistingExports(shellType: ShellType) -> [ParsedExportVariable]

/// 从shell配置文件中删除指定行
func removeExportLine(key: String, shellType: ShellType) throws
```

数据结构：
```swift
struct ParsedExportVariable: Identifiable {
    let id = UUID()
    let key: String
    let value: String
    let rawLine: String        // 原始行内容，用于删除
    let lineNumber: Int        // 行号，用于定位
    let isManaged: Bool        // 是否在iEnvs管理区域内
}
```

解析逻辑：
- 读取 `~/.zshrc` 或 `~/.bashrc`
- 跳过空行和注释行
- 识别 `export KEY=value` 或 `export KEY="value"` 格式
- 跳过iEnvs管理区域内的export
- 支持值中带引号、转义字符的情况

### 阶段2：环境变量 - ViewModel增强

**文件**: `iEnvs/ViewModels/EnvGroupViewModel.swift`

新增属性：
```swift
@Published var existingVariables: [ParsedExportVariable] = []
```

新增方法：
```swift
/// 加载非iEnvs管理的环境变量
func loadExistingVariables()

/// 将现有变量迁移到iEnvs管理（修改时调用）
func migrateExistingVariable(_ variable: ParsedExportVariable, newValue: String?)

/// 删除现有变量（直接从原文件删除）
func deleteExistingVariable(_ variable: ParsedExportVariable)
```

### 阶段3：环境变量 - UI实现

**新建文件**: `iEnvs/Views/Existing/ExistingEnvVariablesView.swift`

视图设计：
- 独立页面或Sheet展示
- 列表展示：Key | Value（敏感值模糊显示）| 操作按钮
- 空状态：提示用户没有检测到非iEnvs管理的环境变量
- 操作按钮：编辑、删除

**新建文件**: `iEnvs/Views/Dialogs/MigrateVariableDialog.swift`

迁移确认对话框：
- 提示文字："此操作会将该环境变量纳入iEnvs管理，并从原配置文件中移除原配置"
- 选择分组：让用户选择迁移到哪个现有分组或创建新分组
- 确认/取消按钮

### 阶段4：Hosts - ViewModel增强

**文件**: `iEnvs/ViewModels/HostsGroupViewModel.swift`

已有 `HostsFileManager.parseExistingHosts()` 可用。

新增属性：
```swift
@Published var existingHosts: [HostEntry] = []
@Published var existingHostsLineMap: [UUID: Int] = [:]  // 用于记录行号
```

新增方法：
```swift
/// 加载非iEnvs管理的hosts条目
func loadExistingHosts()

/// 将现有hosts迁移到iEnvs管理
func migrateExistingHost(_ entry: HostEntry, newIp: String?, newHostname: String?)

/// 删除现有hosts条目（直接从/etc/hosts删除）
func deleteExistingHost(_ entry: HostEntry)
```

### 阶段5：Hosts - UI实现

**新建文件**: `iEnvs/Views/Existing/ExistingHostsView.swift`

与环境变量类似的设计，展示：
- IP地址
- 主机名
- 注释
- 操作按钮

### 阶段6：集成到主界面

**文件**: `iEnvs/Views/MainView.swift`

修改内容：
- 在工具栏添加"导入现有配置"按钮
- 或集成到现有侧边栏作为特殊分组

推荐方案：在主界面添加一个"检测到的配置"区域，按Tab区分环境变量和hosts。

### 阶段7：本地化

**文件**: `iEnvs/Utils/Strings.swift` (或现有的本地化文件)

新增字符串：
- "检测到X个未管理的环境变量"
- "将此配置纳入iEnvs管理？"
- "将从原配置文件中删除此条目"
- "选择目标分组"
- "创建新分组"

## 关键文件列表

| 文件路径 | 修改类型 | 说明 |
|---------|---------|------|
| `iEnvs/Services/ShellConfigManager.swift` | 修改 | 添加解析和删除方法 |
| `iEnvs/ViewModels/EnvGroupViewModel.swift` | 修改 | 添加迁移和删除逻辑 |
| `iEnvs/ViewModels/HostsGroupViewModel.swift` | 修改 | 添加迁移和删除逻辑 |
| `iEnvs/Views/Existing/ExistingEnvVariablesView.swift` | 新建 | 环境变量展示视图 |
| `iEnvs/Views/Existing/ExistingHostsView.swift` | 新建 | Hosts展示视图 |
| `iEnvs/Views/Dialogs/MigrateVariableDialog.swift` | 新建 | 迁移确认对话框 |
| `iEnvs/Views/Dialogs/MigrateHostDialog.swift` | 新建 | Hosts迁移对话框 |
| `iEnvs/Views/MainView.swift` | 修改 | 集成入口 |
| `iEnvs/Utils/Strings.swift` | 修改 | 添加本地化字符串 |

## 核心算法

### 解析export语句正则
```swift
// 匹配 export KEY=value 或 export KEY="value"
// 支持：单引号、双引号、无引号
// 支持：值中包含等号
let pattern = "^\\s*export\\s+([a-zA-Z_][a-zA-Z0-9_]*)\\s*=\\s*(.+)$"
```

### 删除指定行的实现
```swift
// 1. 备份原文件
// 2. 读取所有行
// 3. 根据lineNumber删除对应行
// 4. 原子写入
// 5. 错误时恢复备份
```

## 验证步骤

1. 在 `~/.zshrc` 中添加测试export语句（在iEnvs管理区域外）
2. 启动应用，检查"检测到的配置"是否正确显示
3. 点击编辑，确认迁移流程：
   - 弹出确认对话框 ✓
   - 选择/创建分组 ✓
   - 原配置从~/.zshrc删除 ✓
   - iEnvs管理中新增该变量 ✓
4. 点击删除，确认直接从~/.zshrc删除
5. 对hosts重复以上测试

## 安全考虑

1. 所有文件修改前必须备份
2. 删除操作需要二次确认
3. 解析失败时优雅降级，不崩溃
4. 避免删除iEnvs管理区域内的配置（有UUID标记）
