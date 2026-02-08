# iEnvs 构建配置

## 📦 已创建的文件

### 1. project.yml
XCodeGen 配置文件，用于生成 Xcode 项目。

**配置要点：**
- 项目名称: iEnvs
- Bundle ID: com.ienvs.app
- 部署目标: macOS 13.0+
- Swift 版本: 5.9
- 代码签名: 自动签名（开发用）
- 源文件: 自动包含 iEnvs/ 目录下所有代码

### 2. setup.sh
自动化初始化脚本（已设置可执行权限）。

**功能：**
- 检测 xcodegen 是否安装
- 自动生成 Xcode 项目
- 显示项目结构和统计信息
- 提供多种构建方式的说明

## 🚀 快速开始

### 方式 1: 使用 XCodeGen（推荐）

```bash
# 1. 安装 xcodegen（仅需一次）
brew install xcodegen

# 2. 运行初始化脚本
./setup.sh

# 脚本会自动：
# - 生成 iEnvs.xcodeproj
# - 打开 Xcode
```

### 方式 2: 手动执行

```bash
# 生成项目
xcodegen generate

# 打开项目
open iEnvs.xcodeproj
```

### 方式 3: 手动创建 Xcode 项目

1. 打开 Xcode → File → New → Project
2. 选择 macOS → App
3. 产品名称: iEnvs
4. 界面: SwiftUI
5. 语言: Swift
6. 保存到项目根目录
7. 删除 Xcode 自动生成的文件
8. 将 iEnvs/ 目录下所有 .swift 文件拖入项目

## 📊 项目统计

- **Swift 源文件**: 30 个
- **总代码行数**: 3,255 行
- **架构层次**:
  - Models: 5 个文件
  - Views: 13 个文件
  - ViewModels: 2 个文件
  - Services: 5 个文件
  - Utils: 3 个文件

## 📁 项目结构

```
iEnvs/
├── Models/              # 数据模型
├── Views/               # SwiftUI 视图
│   ├── Components/      # 可复用组件
│   ├── Detail/          # 详情视图
│   ├── Dialogs/         # 对话框
│   ├── Settings/        # 设置界面
│   └── Sidebar/         # 侧边栏
├── ViewModels/          # 视图模型
├── Services/            # 业务逻辑
├── Utils/               # 工具类
└── Resources/           # 资源文件
```

## 🔧 构建要求

- **macOS**: 13.0 或更高版本
- **Xcode**: 15.0 或更高版本
- **Swift**: 5.9 或更高版本

## 📝 相关文档

- [需求文档](docs/PRD.md)
- [系统设计](docs/SystemDesign.md)

## ⚠️ 注意事项

1. **代码签名**: 当前配置为自动签名，开发测试无需额外配置
2. **沙盒**: 应用未启用沙盒（com.apple.security.app-sandbox = false），以便访问 shell 配置文件
3. **首次构建**: 首次打开项目可能需要等待 Xcode 索引完成

## 🎯 下一步

构建完成后，可以：

1. **运行应用**: Cmd+R
2. **运行测试**: Cmd+U（需要添加测试）
3. **归档发布**: Product → Archive

## 🔍 故障排查

### 问题: xcodegen 命令不存在
```bash
brew install xcodegen
```

### 问题: 项目无法构建
1. 清理构建文件: Shift+Cmd+K
2. 重新生成项目: `xcodegen generate`
3. 清理 DerivedData: `rm -rf ~/Library/Developer/Xcode/DerivedData`

### 问题: 代码签名错误
1. 打开 Xcode 项目设置
2. 选择 Target → Signing & Capabilities
3. 确认 Team 已选择
