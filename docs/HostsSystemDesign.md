# iEnvs Hosts 管理系统设计文档

## 1. 架构设计

### 1.1 整体架构

Hosts 管理功能遵循与环境变量管理相同的 MVVM 架构模式：

```
┌─────────────────────────────────────────────────────────┐
│                    Views (SwiftUI)                      │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐ │
│  │HostsSidebar  │  │HostsDetail   │  │HostsDialogs  │ │
│  └──────┬───────┘  └──────┬───────┘  └──────┬───────┘ │
└─────────┼──────────────────┼──────────────────┼─────────┘
          │                  │                  │
          └──────────────────┼──────────────────┘
                             │
                    @ObservedObject
                             │
┌────────────────────────────┴─────────────────────────────┐
│                  ViewModel Layer                         │
│              ┌────────────────────┐                      │
│              │  HostGroupViewModel│                      │
│              │  (HostGroup 管理)  │                      │
│              └──────────┬─────────┘                      │
└─────────────────────────┼────────────────────────────────┘
                          │ 协调
        ┌─────────────────┼─────────────────┐
        │                 │                 │
┌───────┴────────┐ ┌──────┴──────┐ ┌───────┴──────────┐
│HostsFileManager│ │ConflictDet. │ │ImportExport Mgr. │
└───────┬────────┘ └─────────────┘ └──────────────────┘
        │
┌───────┴────────────────────────────────────────────────┐
│              Services & Utilities                      │
│  ┌─────────┐  ┌──────────┐  ┌────────┐  ┌──────────┐ │
│  │DataStore│  │BackupMgr │  │Logger  │  │Validators│ │
│  └─────────┘  └──────────┘  └────────┘  └──────────┘ │
└────────────────────────────────────────────────────────┘
```

### 1.2 模块职责

| 模块 | 职责 |
|------|------|
| **HostGroupViewModel** | 管理 hosts 分组和条目的增删改查、启用/禁用协调、冲突检测触发 |
| **HostsFileManager** | 读写 `/etc/hosts` 文件、标记块管理、权限处理、DNS 缓存刷新 |
| **HostsConflictDetector** | 检测域名冲突、生成冲突报告 |
| **HostsImportExportManager** | 导入导出 JSON 和 hosts 文件格式 |
| **DataStore** | 持久化 hosts 数据到 JSON 文件 |
| **BackupManager** | 备份和恢复 `/etc/hosts` 文件 |

### 1.3 数据流

```
用户操作 → View → ViewModel → Service → 文件系统
                    ↓
            @Published 属性更新
                    ↓
            View 自动刷新
```

**启用分组流程：**
```
1. 用户点击开关 → HostsSidebar
2. ViewModel.toggleHostGroup(id)
3. ConflictDetector.checkConflicts(newGroups)
4. 如有冲突 → 显示对话框 → 用户取消/继续
5. BackupManager.backup("/etc/hosts")
6. HostsFileManager.writeHostsFile(enabledGroups)
7. HostsFileManager.flushDNSCache()
8. DataStore.save(appData)
9. @Published hostsGroups 更新 → UI 刷新
```

## 2. 数据模型设计

### 2.1 核心模型

#### HostEntry（Hosts 条目）

```swift
struct HostEntry: Identifiable, Codable, Hashable {
    let id: UUID
    var ipAddress: String          // IPv4 或 IPv6 地址
    var hostname: String            // 域名
    var comment: String?            // 可选备注
    var createdAt: Date
    var updatedAt: Date

    init(ipAddress: String, hostname: String, comment: String? = nil) {
        self.id = UUID()
        self.ipAddress = ipAddress
        self.hostname = hostname
        self.comment = comment
        self.createdAt = Date()
        self.updatedAt = Date()
    }
}
```

**字段说明：**
- `ipAddress`：支持 IPv4 (如 `127.0.0.1`) 和 IPv6 (如 `::1`)
- `hostname`：域名或主机名，支持通配符（如 `*.test.com`，仅用于显示，系统 hosts 不支持通配符）
- `comment`：用户备注，不写入 `/etc/hosts` 文件

**验证规则：**
- `ipAddress`：使用 `Validators.isValidIPAddress()` 验证
- `hostname`：使用 `Validators.isValidHostname()` 验证（允许字母、数字、连字符、点）

#### HostGroup（Hosts 分组）

```swift
struct HostGroup: Identifiable, Codable, Hashable {
    let id: UUID
    var name: String
    var description: String?
    var entries: [HostEntry]
    var isEnabled: Bool
    var colorTag: ColorTag?          // 可选颜色标签
    var order: Int                   // 排序序号
    var createdAt: Date
    var updatedAt: Date

    init(name: String, description: String? = nil) {
        self.id = UUID()
        self.name = name
        self.description = description
        self.entries = []
        self.isEnabled = false
        self.colorTag = nil
        self.order = 0
        self.createdAt = Date()
        self.updatedAt = Date()
    }

    var enabledEntriesCount: Int {
        entries.count
    }
}
```

**字段说明：**
- `id`：唯一标识符，用于在 `/etc/hosts` 文件中标记该分组的内容块
- `isEnabled`：是否启用（写入 `/etc/hosts`）
- `order`：用户自定义排序序号
- `colorTag`：用于 UI 显示的颜色标签（红、橙、黄、绿、蓝、紫）

#### ColorTag（颜色标签）

```swift
enum ColorTag: String, Codable, CaseIterable {
    case red = "红色"
    case orange = "橙色"
    case yellow = "黄色"
    case green = "绿色"
    case blue = "蓝色"
    case purple = "紫色"

    var color: Color {
        switch self {
        case .red: return .red
        case .orange: return .orange
        case .yellow: return .yellow
        case .green: return .green
        case .blue: return .blue
        case .purple: return .purple
        }
    }
}
```

### 2.2 扩展现有模型

#### AppData 扩展

```swift
struct AppData: Codable {
    var groups: [EnvGroup]              // 现有：环境变量分组
    var hostGroups: [HostGroup]         // 新增：Hosts 分组
    var settings: AppSettings

    static var empty: AppData {
        AppData(groups: [], hostGroups: [], settings: AppSettings())
    }
}
```

### 2.3 冲突检测模型

#### HostConflict（冲突报告）

```swift
struct HostConflict: Identifiable {
    let id = UUID()
    let hostname: String                           // 冲突的域名
    let conflictingEntries: [ConflictingEntry]     // 冲突条目列表

    struct ConflictingEntry {
        let groupId: UUID
        let groupName: String
        let ipAddress: String
    }

    var description: String {
        let ips = conflictingEntries.map { "\($0.ipAddress) (来自 \($0.groupName))" }
        return "域名 \(hostname) 在多个分组中有不同定义：\n" + ips.joined(separator: "\n")
    }
}
```

## 3. 服务层设计

### 3.1 HostsFileManager（核心服务）

#### 职责
- 读写 `/etc/hosts` 文件
- 管理标记块（使用 UUID 标识不同分组）
- 处理 sudo 权限（通过 AppleScript）
- 刷新 DNS 缓存

#### 关键方法

```swift
class HostsFileManager {
    static let shared = HostsFileManager()

    private let hostsFilePath = "/etc/hosts"
    private let markerStart = "# ========== iEnvs Managed Hosts =========="
    private let markerEnd = "# ========== End of iEnvs Managed Hosts =========="

    // 读取 /etc/hosts 文件内容
    func readHostsFile() throws -> String

    // 写入启用的分组到 /etc/hosts
    func writeHostsFile(enabledGroups: [HostGroup]) throws

    // 刷新 DNS 缓存
    func flushDNSCache() throws

    // 使用 AppleScript 执行需要 sudo 权限的命令
    private func executeWithAdminPrivileges(_ command: String) throws -> String

    // 生成分组标记块内容
    private func generateGroupBlock(group: HostGroup) -> String

    // 解析现有 /etc/hosts 文件，提取非 iEnvs 管理的内容
    private func extractUnmanagedContent(from content: String) -> String
}
```

#### 标记块格式

```
# ========== iEnvs Managed Hosts ==========
# [iEnvsHosts:550e8400-e29b-41d4-a716-446655440000] START - 本地开发
127.0.0.1    api.test.com
192.168.1.100    db.test.com
# [iEnvsHosts:550e8400-e29b-41d4-a716-446655440000] END - 本地开发

# [iEnvsHosts:660e8400-e29b-41d4-a716-446655440001] START - 广告屏蔽
0.0.0.0    ads.example.com
0.0.0.0    tracker.example.com
# [iEnvsHosts:660e8400-e29b-41d4-a716-446655440001] END - 广告屏蔽
# ========== End of iEnvs Managed Hosts ==========
```

**标记规则：**
- 使用分组的 UUID 作为唯一标识
- 分组名称仅用于可读性，UUID 才是真实标识
- 标记块位于用户手动添加内容之后，避免影响系统默认配置

#### 写入流程伪代码

```swift
func writeHostsFile(enabledGroups: [HostGroup]) throws {
    // 1. 读取现有 /etc/hosts 文件
    let originalContent = try readHostsFile()

    // 2. 提取非 iEnvs 管理的内容（移除旧的标记块）
    let unmanagedContent = extractUnmanagedContent(from: originalContent)

    // 3. 生成新的标记块内容
    var managedContent = markerStart + "\n"
    for group in enabledGroups {
        managedContent += generateGroupBlock(group: group)
    }
    managedContent += markerEnd + "\n"

    // 4. 合并内容
    let newContent = unmanagedContent + "\n" + managedContent

    // 5. 写入临时文件
    let tempFile = "/tmp/hosts.tmp.\(UUID().uuidString)"
    try newContent.write(toFile: tempFile, atomically: true, encoding: .utf8)

    // 6. 使用 AppleScript 执行 sudo mv
    let command = "mv '\(tempFile)' '\(hostsFilePath)' && chmod 644 '\(hostsFilePath)'"
    try executeWithAdminPrivileges(command)

    // 7. 刷新 DNS 缓存
    try flushDNSCache()
}
```

#### AppleScript 权限处理

```swift
private func executeWithAdminPrivileges(_ command: String) throws -> String {
    let script = """
    do shell script "\(command)" with administrator privileges
    """

    var error: NSDictionary?
    guard let scriptObject = NSAppleScript(source: script) else {
        throw HostsError.scriptCreationFailed
    }

    let output = scriptObject.executeAndReturnError(&error)

    if let error = error {
        throw HostsError.permissionDenied(error.description)
    }

    return output.stringValue ?? ""
}
```

#### DNS 缓存刷新

```swift
func flushDNSCache() throws {
    // macOS 不同版本的刷新命令
    let commands = [
        "dscacheutil -flushcache",
        "sudo killall -HUP mDNSResponder"
    ]

    for command in commands {
        do {
            try executeWithAdminPrivileges(command)
        } catch {
            Logger.shared.warning("DNS 刷新命令执行失败: \(command)")
        }
    }
}
```

### 3.2 HostsConflictDetector（冲突检测）

#### 职责
- 检测启用分组间的域名冲突
- 生成冲突报告

#### 关键方法

```swift
class HostsConflictDetector {
    // 检测分组间的域名冲突
    static func detectConflicts(in groups: [HostGroup]) -> [HostConflict] {
        var hostnameMap: [String: [HostConflict.ConflictingEntry]] = [:]

        // 遍历所有启用的分组
        for group in groups where group.isEnabled {
            for entry in group.entries {
                let hostname = entry.hostname.lowercased()
                let conflictEntry = HostConflict.ConflictingEntry(
                    groupId: group.id,
                    groupName: group.name,
                    ipAddress: entry.ipAddress
                )
                hostnameMap[hostname, default: []].append(conflictEntry)
            }
        }

        // 筛选出有冲突的域名（同一域名有多个不同 IP）
        var conflicts: [HostConflict] = []
        for (hostname, entries) in hostnameMap {
            let uniqueIPs = Set(entries.map { $0.ipAddress })
            if uniqueIPs.count > 1 {
                conflicts.append(HostConflict(hostname: hostname, conflictingEntries: entries))
            }
        }

        return conflicts
    }

    // 检查启用特定分组是否会引发新冲突
    static func checkConflictForEnabling(group: HostGroup, withExisting groups: [HostGroup]) -> [HostConflict] {
        var tempGroups = groups.filter { $0.isEnabled }
        tempGroups.append(group)
        return detectConflicts(in: tempGroups)
    }
}
```

### 3.3 HostsImportExportManager（导入导出）

#### 职责
- 导出为 JSON 或 hosts 文件格式
- 从 JSON 或 hosts 文件导入

#### 关键方法

```swift
class HostsImportExportManager {
    // 导出所有分组为 JSON
    static func exportToJSON(groups: [HostGroup]) throws -> Data {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        return try encoder.encode(groups)
    }

    // 从 JSON 导入分组
    static func importFromJSON(data: Data) throws -> [HostGroup] {
        let decoder = JSONDecoder()
        return try decoder.decode([HostGroup].self, from: data)
    }

    // 导出单个分组为 hosts 文件格式
    static func exportToHostsFile(group: HostGroup) -> String {
        var content = "# \(group.name)\n"
        if let description = group.description {
            content += "# \(description)\n"
        }
        content += "# 导出时间: \(Date().formatted())\n\n"

        for entry in group.entries {
            // 对齐格式：IP 地址左对齐 20 字符，然后是域名
            let line = String(format: "%-20s %@", entry.ipAddress, entry.hostname)
            if let comment = entry.comment {
                content += "\(line)    # \(comment)\n"
            } else {
                content += "\(line)\n"
            }
        }

        return content
    }

    // 从 hosts 文件格式导入
    static func importFromHostsFile(content: String, groupName: String) throws -> HostGroup {
        var group = HostGroup(name: groupName)
        let lines = content.components(separatedBy: .newlines)

        for line in lines {
            // 移除行内注释
            let parts = line.components(separatedBy: "#")
            guard let mainPart = parts.first?.trimmingCharacters(in: .whitespaces),
                  !mainPart.isEmpty else {
                continue
            }

            // 解析 IP 和域名
            let components = mainPart.components(separatedBy: .whitespaces)
                .filter { !$0.isEmpty }
            guard components.count >= 2 else { continue }

            let ipAddress = components[0]
            let hostname = components[1]

            // 验证格式
            guard Validators.isValidIPAddress(ipAddress),
                  Validators.isValidHostname(hostname) else {
                Logger.shared.warning("跳过无效条目: \(line)")
                continue
            }

            // 提取注释（如果存在）
            let comment = parts.count > 1 ? parts[1].trimmingCharacters(in: .whitespaces) : nil

            group.entries.append(HostEntry(
                ipAddress: ipAddress,
                hostname: hostname,
                comment: comment
            ))
        }

        return group
    }
}
```

### 3.4 BackupManager 扩展

复用现有 `BackupManager`，添加 hosts 文件备份支持：

```swift
extension BackupManager {
    private let hostsBackupDirectory = FileManager.default.homeDirectoryForCurrentUser
        .appendingPathComponent("Library/Application Support/iEnvs/backups/hosts")

    // 备份 /etc/hosts 文件
    func backupHostsFile() throws -> URL {
        let timestamp = ISO8601DateFormatter().string(from: Date())
        let backupFileName = "hosts_backup_\(timestamp).txt"
        let backupURL = hostsBackupDirectory.appendingPathComponent(backupFileName)

        // 创建备份目录
        try FileManager.default.createDirectory(at: hostsBackupDirectory,
                                                withIntermediateDirectories: true)

        // 复制文件
        let hostsURL = URL(fileURLWithPath: "/etc/hosts")
        try FileManager.default.copyItem(at: hostsURL, to: backupURL)

        Logger.shared.info("已备份 /etc/hosts 文件到: \(backupURL.path)")
        return backupURL
    }

    // 恢复 hosts 文件备份
    func restoreHostsBackup(from backupURL: URL) throws {
        let content = try String(contentsOf: backupURL, encoding: .utf8)
        // 使用 HostsFileManager 写入（需要 sudo 权限）
        try HostsFileManager.shared.restoreFromBackup(content: content)
    }
}
```

## 4. ViewModel 设计

### 4.1 HostGroupViewModel

```swift
@MainActor
class HostGroupViewModel: ObservableObject {
    @Published var hostGroups: [HostGroup] = []
    @Published var selectedGroupId: UUID?
    @Published var showConflictAlert: Bool = false
    @Published var currentConflicts: [HostConflict] = []
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?

    private let dataStore = DataStore.shared
    private let hostsFileManager = HostsFileManager.shared

    // 初始化：加载数据并同步状态
    init() {
        loadData()
        syncStateWithHostsFile()
    }

    // MARK: - 分组管理

    func createGroup(name: String, description: String?) {
        var group = HostGroup(name: name, description: description)
        group.order = hostGroups.count
        hostGroups.append(group)
        saveData()
    }

    func updateGroup(_ group: HostGroup) {
        if let index = hostGroups.firstIndex(where: { $0.id == group.id }) {
            hostGroups[index] = group
            saveData()
        }
    }

    func deleteGroup(id: UUID) {
        // 如果分组已启用，先禁用
        if let group = hostGroups.first(where: { $0.id == id }), group.isEnabled {
            disableGroup(id: id)
        }
        hostGroups.removeAll { $0.id == id }
        saveData()
    }

    func reorderGroups(from: IndexSet, to: Int) {
        hostGroups.move(fromOffsets: from, toOffset: to)
        // 更新 order 字段
        for (index, _) in hostGroups.enumerated() {
            hostGroups[index].order = index
        }
        saveData()
    }

    // MARK: - 条目管理

    func addEntry(to groupId: UUID, entry: HostEntry) {
        if let index = hostGroups.firstIndex(where: { $0.id == groupId }) {
            hostGroups[index].entries.append(entry)
            hostGroups[index].updatedAt = Date()

            // 如果分组已启用，重新写入 hosts 文件
            if hostGroups[index].isEnabled {
                syncHostsFile()
            }
            saveData()
        }
    }

    func updateEntry(in groupId: UUID, entry: HostEntry) {
        if let groupIndex = hostGroups.firstIndex(where: { $0.id == groupId }),
           let entryIndex = hostGroups[groupIndex].entries.firstIndex(where: { $0.id == entry.id }) {
            hostGroups[groupIndex].entries[entryIndex] = entry
            hostGroups[groupIndex].updatedAt = Date()

            if hostGroups[groupIndex].isEnabled {
                syncHostsFile()
            }
            saveData()
        }
    }

    func deleteEntry(from groupId: UUID, entryId: UUID) {
        if let groupIndex = hostGroups.firstIndex(where: { $0.id == groupId }) {
            hostGroups[groupIndex].entries.removeAll { $0.id == entryId }
            hostGroups[groupIndex].updatedAt = Date()

            if hostGroups[groupIndex].isEnabled {
                syncHostsFile()
            }
            saveData()
        }
    }

    // MARK: - 启用/禁用

    func toggleGroup(id: UUID) {
        guard let index = hostGroups.firstIndex(where: { $0.id == id }) else { return }

        if hostGroups[index].isEnabled {
            // 禁用分组
            disableGroup(id: id)
        } else {
            // 启用分组前检测冲突
            let conflicts = HostsConflictDetector.checkConflictForEnabling(
                group: hostGroups[index],
                withExisting: hostGroups
            )

            if !conflicts.isEmpty {
                currentConflicts = conflicts
                showConflictAlert = true
                return
            }

            enableGroup(id: id)
        }
    }

    func enableGroup(id: UUID) {
        guard let index = hostGroups.firstIndex(where: { $0.id == id }) else { return }

        isLoading = true
        hostGroups[index].isEnabled = true

        do {
            // 备份现有 hosts 文件
            _ = try BackupManager.shared.backupHostsFile()

            // 写入 hosts 文件
            try syncHostsFile()

            saveData()
            Logger.shared.info("已启用 hosts 分组: \(hostGroups[index].name)")
        } catch {
            // 回滚状态
            hostGroups[index].isEnabled = false
            errorMessage = "启用分组失败: \(error.localizedDescription)"
            Logger.shared.error("启用 hosts 分组失败: \(error)")
        }

        isLoading = false
    }

    func disableGroup(id: UUID) {
        guard let index = hostGroups.firstIndex(where: { $0.id == id }) else { return }

        isLoading = true
        hostGroups[index].isEnabled = false

        do {
            _ = try BackupManager.shared.backupHostsFile()
            try syncHostsFile()
            saveData()
            Logger.shared.info("已禁用 hosts 分组: \(hostGroups[index].name)")
        } catch {
            hostGroups[index].isEnabled = true
            errorMessage = "禁用分组失败: \(error.localizedDescription)"
            Logger.shared.error("禁用 hosts 分组失败: \(error)")
        }

        isLoading = false
    }

    func forceEnableGroupIgnoringConflicts(id: UUID) {
        showConflictAlert = false
        enableGroup(id: id)
    }

    // MARK: - 文件同步

    private func syncHostsFile() throws {
        let enabledGroups = hostGroups.filter { $0.isEnabled }
        try hostsFileManager.writeHostsFile(enabledGroups: enabledGroups)
    }

    private func syncStateWithHostsFile() {
        // 应用启动时，检查 /etc/hosts 文件内容，同步启用状态
        // 读取文件，解析标记块，更新对应分组的 isEnabled 状态
        // 实现细节省略
    }

    // MARK: - 数据持久化

    private func loadData() {
        if let appData = dataStore.load() {
            hostGroups = appData.hostGroups.sorted { $0.order < $1.order }
        }
    }

    private func saveData() {
        var appData = dataStore.load() ?? AppData.empty
        appData.hostGroups = hostGroups
        dataStore.save(appData)
    }
}
```

## 5. UI 设计

### 5.1 主界面结构

```swift
struct HostsManagementView: View {
    @StateObject private var viewModel = HostGroupViewModel()

    var body: some View {
        NavigationSplitView {
            HostsSidebarView(viewModel: viewModel)
        } detail: {
            if let selectedId = viewModel.selectedGroupId,
               let group = viewModel.hostGroups.first(where: { $0.id == selectedId }) {
                HostsDetailView(group: group, viewModel: viewModel)
            } else {
                HostsEmptyStateView()
            }
        }
        .alert("检测到域名冲突", isPresented: $viewModel.showConflictAlert) {
            Button("取消", role: .cancel) {}
            Button("仍然启用", role: .destructive) {
                viewModel.forceEnableGroupIgnoringConflicts(id: viewModel.selectedGroupId!)
            }
        } message: {
            Text(viewModel.currentConflicts.map { $0.description }.joined(separator: "\n\n"))
        }
        .overlay {
            if viewModel.isLoading {
                ProgressView("正在更新 hosts 文件...")
            }
        }
    }
}
```

### 5.2 侧边栏

```swift
struct HostsSidebarView: View {
    @ObservedObject var viewModel: HostGroupViewModel
    @State private var showCreateDialog = false

    var body: some View {
        List(selection: $viewModel.selectedGroupId) {
            ForEach(viewModel.hostGroups) { group in
                HostsGroupRowView(group: group, viewModel: viewModel)
            }
            .onMove { from, to in
                viewModel.reorderGroups(from: from, to: to)
            }
        }
        .navigationTitle("Hosts 分组")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    showCreateDialog = true
                } label: {
                    Label("添加分组", systemImage: "plus")
                }
            }
        }
        .sheet(isPresented: $showCreateDialog) {
            CreateHostGroupDialog(viewModel: viewModel)
        }
    }
}

struct HostsGroupRowView: View {
    let group: HostGroup
    @ObservedObject var viewModel: HostGroupViewModel

    var body: some View {
        HStack {
            // 颜色标签
            if let colorTag = group.colorTag {
                Circle()
                    .fill(colorTag.color)
                    .frame(width: 8, height: 8)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(group.name)
                    .font(.headline)
                Text("\(group.entries.count) 条记录")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()

            // 启用开关
            Toggle("", isOn: Binding(
                get: { group.isEnabled },
                set: { _ in viewModel.toggleGroup(id: group.id) }
            ))
            .toggleStyle(.switch)
        }
        .padding(.vertical, 4)
    }
}
```

### 5.3 详情面板

```swift
struct HostsDetailView: View {
    let group: HostGroup
    @ObservedObject var viewModel: HostGroupViewModel
    @State private var showAddDialog = false

    var body: some View {
        VStack(spacing: 0) {
            // 分组信息头部
            HostsGroupHeaderView(group: group)

            Divider()

            // 条目列表
            List {
                ForEach(group.entries) { entry in
                    HostsEntryRowView(entry: entry, groupId: group.id, viewModel: viewModel)
                }
            }
            .listStyle(.plain)
        }
        .toolbar {
            ToolbarItem {
                Button {
                    showAddDialog = true
                } label: {
                    Label("添加条目", systemImage: "plus")
                }
            }
        }
        .sheet(isPresented: $showAddDialog) {
            AddHostEntryDialog(groupId: group.id, viewModel: viewModel)
        }
    }
}

struct HostsEntryRowView: View {
    let entry: HostEntry
    let groupId: UUID
    @ObservedObject var viewModel: HostGroupViewModel

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(entry.hostname)
                    .font(.headline)
                Text(entry.ipAddress)
                    .font(.caption)
                    .foregroundColor(.secondary)
                if let comment = entry.comment {
                    Text(comment)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                        .italic()
                }
            }

            Spacer()

            Button {
                // 编辑操作
            } label: {
                Image(systemName: "pencil")
            }
            .buttonStyle(.plain)

            Button(role: .destructive) {
                viewModel.deleteEntry(from: groupId, entryId: entry.id)
            } label: {
                Image(systemName: "trash")
            }
            .buttonStyle(.plain)
        }
        .padding(.vertical, 4)
    }
}
```

## 6. 权限处理方案

### 6.1 AppleScript 执行方式

```applescript
do shell script "mv '/tmp/hosts.tmp' '/etc/hosts' && chmod 644 '/etc/hosts'" with administrator privileges
```

- 系统会自动弹出密码输入对话框
- 用户输入管理员密码后执行命令
- 密码输入失败或取消时抛出错误

### 6.2 错误处理

```swift
enum HostsError: LocalizedError {
    case permissionDenied(String)
    case fileNotFound
    case invalidFormat
    case scriptCreationFailed

    var errorDescription: String? {
        switch self {
        case .permissionDenied(let detail):
            return "权限被拒绝: \(detail)。请确保您有管理员权限。"
        case .fileNotFound:
            return "未找到 /etc/hosts 文件"
        case .invalidFormat:
            return "hosts 文件格式无效"
        case .scriptCreationFailed:
            return "无法创建 AppleScript 脚本"
        }
    }
}
```

## 7. 安全考虑

### 7.1 输入验证

```swift
class Validators {
    // 验证 IPv4 地址
    static func isValidIPv4(_ ip: String) -> Bool {
        let parts = ip.split(separator: ".")
        guard parts.count == 4 else { return false }
        return parts.allSatisfy { part in
            guard let num = Int(part), num >= 0, num <= 255 else { return false }
            return true
        }
    }

    // 验证 IPv6 地址
    static func isValidIPv6(_ ip: String) -> Bool {
        // 简化实现：使用正则表达式
        let pattern = "^(([0-9a-fA-F]{1,4}:){7}[0-9a-fA-F]{1,4}|::)$"
        return ip.range(of: pattern, options: .regularExpression) != nil
    }

    // 验证 IP 地址（IPv4 或 IPv6）
    static func isValidIPAddress(_ ip: String) -> Bool {
        return isValidIPv4(ip) || isValidIPv6(ip)
    }

    // 验证主机名
    static func isValidHostname(_ hostname: String) -> Bool {
        // 允许：字母、数字、连字符、点
        // 不允许：以连字符开头或结尾
        let pattern = "^[a-zA-Z0-9]([a-zA-Z0-9\\-\\.]{0,253}[a-zA-Z0-9])?$"
        return hostname.range(of: pattern, options: .regularExpression) != nil
    }
}
```

### 7.2 原子写入

```swift
// 1. 写入临时文件
let tempFile = "/tmp/hosts.tmp.\(UUID().uuidString)"
try newContent.write(toFile: tempFile, atomically: true, encoding: .utf8)

// 2. 原子替换
try executeWithAdminPrivileges("mv '\(tempFile)' '/etc/hosts'")

// 3. 失败时清理临时文件
defer {
    try? FileManager.default.removeItem(atPath: tempFile)
}
```

### 7.3 备份策略

- 每次修改 `/etc/hosts` 前自动备份
- 备份文件保留 30 天
- 备份文件权限与原文件一致（600）

### 7.4 注入防护

```swift
// 防止换行符注入
private func sanitizeInput(_ input: String) -> String {
    return input
        .replacingOccurrences(of: "\n", with: " ")
        .replacingOccurrences(of: "\r", with: " ")
        .trimmingCharacters(in: .whitespacesAndNewlines)
}
```

## 8. 性能优化

### 8.1 大规模条目处理

- 使用 `LazyVStack` 延迟加载列表
- 条目数超过 100 时启用分页显示
- 冲突检测使用哈希表，时间复杂度 O(n)

### 8.2 文件写入优化

- 批量操作合并为单次写入
- 使用临时文件避免部分写入导致的文件损坏

### 8.3 内存管理

- 避免在内存中存储完整 `/etc/hosts` 文件内容
- 流式读取和写入大文件

## 9. 测试策略

### 9.1 单元测试

- `Validators` 输入验证测试
- `HostsConflictDetector` 冲突检测逻辑测试
- `HostsImportExportManager` 格式转换测试

### 9.2 集成测试

- 完整的启用/禁用流程测试
- 权限处理测试（需要手动触发）
- 备份恢复测试

### 9.3 手动测试清单

- [ ] 创建分组并添加条目
- [ ] 启用分组后，使用 `ping` 验证条目生效
- [ ] 禁用分组后，验证条目失效
- [ ] 启用包含冲突的分组，验证警告对话框显示
- [ ] 导出为 JSON，删除分组，重新导入，验证数据完整性
- [ ] 导入现有 `/etc/hosts` 文件，验证解析正确性
- [ ] 应用重启后，验证启用状态与文件内容一致
- [ ] 手动修改 `/etc/hosts` 中的 iEnvs 标记块，验证应用检测并提示修复

## 10. 发布检查清单

- [ ] 所有核心功能实现完成
- [ ] 输入验证覆盖所有用户输入点
- [ ] 错误提示使用中文且描述清晰
- [ ] 权限处理正常工作
- [ ] 备份机制可靠
- [ ] 冲突检测准确
- [ ] 界面与环境变量管理保持一致
- [ ] 性能测试通过（500 条记录以内响应时间 < 2s）
- [ ] 手动测试清单全部通过
- [ ] 文档更新（README、用户手册）
