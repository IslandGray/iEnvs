# Release - iEnvs 发布工作流

## Description
自动化 iEnvs 应用的完整发布流程：更新版本号、构建、打包 DMG、提交代码、推送到 GitHub 并创建 Release。

## Trigger
当用户说 "release"、"发布"、"打包发布"、"创建新版本" 时触发。

## Arguments
- `version`: 新版本号（如 `1.0.2`），必需
- `notes`: 发布说明（可选，不提供则会询问）

## Instructions

### 步骤 1：确认版本信息
- 如果用户未提供版本号，询问新版本号
- 如果用户未提供发布说明，询问本次更新内容
- 读取当前 `iEnvs/Info.plist` 获取当前版本号和构建号

### 步骤 2：更新版本号
- 更新 `iEnvs/Info.plist` 中的 `CFBundleShortVersionString` 为新版本号
- 更新 `CFBundleVersion`（在当前构建号基础上 +1）

### 步骤 3：重新生成 Xcode 项目
```bash
xcodegen generate
```
注意：xcodegen 会覆盖 Info.plist，需要在生成后重新设置版本号。

### 步骤 4：构建 Release 版本
```bash
xcodebuild -project iEnvs.xcodeproj -scheme iEnvs -configuration Release clean build SYMROOT=build
```

### 步骤 5：创建 DMG 安装包
```bash
rm -rf build/dmg-staging
mkdir -p build/dmg-staging
cp -R build/Release/iEnvs.app build/dmg-staging/
ln -sf /Applications build/dmg-staging/Applications
hdiutil create -volname "iEnvs" -srcfolder build/dmg-staging -ov -format UDZO build/iEnvs-{version}.dmg
```

### 步骤 6：提交并推送代码
```bash
git add -A
git commit -m "chore: bump version to {version}

{发布说明摘要}

Co-Authored-By: Claude Opus 4.6 <noreply@anthropic.com>"
git push origin main
```

### 步骤 7：创建 GitHub Release
```bash
gh release create v{version} build/iEnvs-{version}.dmg --title "v{version}" --notes "{release notes}"
```
Release notes 格式应包含：
- `## 更新内容 / What's Changed` — 中英双语更新说明
- `## 安装 / Install` — 安装指引

### 步骤 8：确认完成
- 输出 GitHub Release URL
- 汇总所有完成的步骤
