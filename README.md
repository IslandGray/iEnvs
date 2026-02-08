# iEnvs

macOS 环境变量可视化管理工具。通过直观的图形界面，轻松创建、管理和切换不同场景下的环境变量配置，告别繁琐的命令行操作和配置文件编辑。

![Platform](https://img.shields.io/badge/platform-macOS%2013.0%2B-blue)
![Swift](https://img.shields.io/badge/Swift-5.9%2B-orange)
![License](https://img.shields.io/badge/license-MIT-green)

## 功能特性

- **分组管理** — 将环境变量按项目或场景组织到不同分组中
- **一键切换** — 通过开关启用/禁用分组，自动写入 Shell 配置文件
- **冲突检测** — 多个分组包含同名变量时自动提示冲突
- **导入导出** — 支持 JSON 和 Shell 脚本格式的导入导出
- **自动备份** — 每次修改 Shell 配置文件前自动创建备份
- **搜索过滤** — 全局搜索分组名称、变量名和变量值
- **敏感信息保护** — 支持标记敏感变量，界面上自动隐藏
- **深色模式** — 自动跟随系统外观

## 截图

> *（待添加）*

## 系统要求

- macOS 13.0 (Ventura) 或更高版本
- 支持 Intel 和 Apple Silicon

## 安装

### 从源码构建

```bash
# 克隆项目
git clone https://github.com/yourname/ienvs.git
cd ienvs

# 安装 XcodeGen（仅需一次）
brew install xcodegen

# 生成 Xcode 项目并打开
xcodegen generate
open iEnvs.xcodeproj
```

在 Xcode 中按 `Cmd+R` 即可构建并运行。

也可以使用初始化脚本一键完成：

```bash
./setup.sh
```

### 命令行构建

```bash
xcodebuild -project iEnvs.xcodeproj -scheme iEnvs -configuration Release build SYMROOT=build
```

构建产物位于 `build/Build/Products/Release/iEnvs.app`。

## 使用方法

### 快速开始

1. 打开 iEnvs，点击左下角 **"+"** 按钮创建新分组（如 "前端开发"）
2. 在右侧面板中添加环境变量（如 `NODE_ENV=development`）
3. 打开分组旁的开关，iEnvs 会自动将变量写入 `~/.zshrc`
4. 在终端中执行 `source ~/.zshrc` 使配置生效

### Shell 配置文件

iEnvs 在你的 Shell 配置文件中维护一个标记区域：

```bash
# ========== iEnvs Managed Variables ==========
# [iEnvs:UUID] START - 分组名称
export NODE_ENV=development
export API_KEY="your-api-key"
# [iEnvs:UUID] END - 分组名称
# ========== End of iEnvs Managed Variables ==========
```

支持的 Shell：
- **Zsh**（macOS 默认）— 写入 `~/.zshrc`
- **Bash** — 写入 `~/.bashrc` 或 `~/.bash_profile`

### 键盘快捷键

| 快捷键 | 操作 |
|--------|------|
| `Cmd+N` | 新建分组 |
| `Cmd+F` | 搜索 |
| `Cmd+,` | 打开设置 |
| `Cmd+Delete` | 删除选中项 |
| `Cmd+Z` | 撤销 |

### 导入导出

- **导出为 JSON** — 完整的分组配置，适合备份和团队分享
- **导出为 Shell 脚本** — 生成可直接 `source` 的 `.sh` 文件
- **从 JSON 导入** — 支持跳过、覆盖或重命名冲突分组

## 技术栈

| 技术 | 用途 |
|------|------|
| Swift 5.9+ | 开发语言 |
| SwiftUI | 原生 UI 框架 |
| Foundation | 核心系统库 |
| XcodeGen | 项目文件生成 |

纯原生实现，无第三方依赖，无网络请求，完全离线运行。

## 项目结构

```
iEnvs/
├── Models/          # 数据模型（EnvGroup, EnvVariable, AppSettings 等）
├── ViewModels/      # 视图模型（EnvGroupViewModel, SettingsViewModel）
├── Views/           # SwiftUI 视图
│   ├── Sidebar/     # 左侧分组列表
│   ├── Detail/      # 右侧变量详情
│   ├── Settings/    # 设置界面
│   ├── Dialogs/     # 对话框
│   └── Components/  # 可复用组件
├── Services/        # 业务逻辑（DataStore, ShellConfigManager, BackupManager 等）
├── Utils/           # 工具类（Constants, Validators, Logger）
└── Resources/       # 资源文件（Assets, Info.plist, Entitlements）
```

## 数据存储

- 应用数据：`~/Library/Application Support/iEnvs/data.json`
- 配置备份：`~/Library/Application Support/iEnvs/backups/`
- 日志：`~/Library/Logs/iEnvs/`

## 文档

- [产品需求文档 (PRD)](docs/PRD.md)
- [系统设计文档](docs/SystemDesign.md)

## 许可证

MIT License
