#!/bin/bash

# iEnvs 项目初始化脚本
# 用法: ./setup.sh

set -e

echo "========================================="
echo "  iEnvs 项目初始化"
echo "========================================="
echo ""

PROJECT_DIR="$(cd "$(dirname "$0")" && pwd)"
cd "$PROJECT_DIR"

# 检查 xcodegen 是否安装
if command -v xcodegen &> /dev/null; then
    echo "✅ 检测到 xcodegen，正在生成 Xcode 项目..."
    xcodegen generate
    echo "✅ Xcode 项目已生成"
    echo ""
    echo "正在打开 Xcode..."
    open iEnvs.xcodeproj
else
    echo "⚠️  未检测到 xcodegen"
    echo ""
    echo "请选择以下方式之一来构建项目："
    echo ""
    echo "方式 1: 安装 xcodegen 后生成项目"
    echo "  brew install xcodegen"
    echo "  xcodegen generate"
    echo "  open iEnvs.xcodeproj"
    echo ""
    echo "方式 2: 手动创建 Xcode 项目"
    echo "  1. 打开 Xcode → File → New → Project"
    echo "  2. 选择 macOS → App"
    echo "  3. 产品名称: iEnvs"
    echo "  4. 界面: SwiftUI"
    echo "  5. 语言: Swift"
    echo "  6. 保存到本目录"
    echo "  7. 删除 Xcode 自动生成的文件"
    echo "  8. 将 iEnvs/ 目录下所有 .swift 文件拖入项目"
    echo ""
    echo "方式 3: 使用 swift build 编译（仅编译验证）"
    echo "  注意：SwiftUI macOS App 需要 Xcode 项目才能完整运行"
fi

echo ""
echo "========================================="
echo "  项目结构"
echo "========================================="
echo ""

# 显示项目结构
if command -v tree &> /dev/null; then
    tree -I '.omc|docs|.git|*.md' --dirsfirst iEnvs/
else
    find iEnvs/ -name "*.swift" -o -name "*.plist" -o -name "*.json" -o -name "*.entitlements" | sort
fi

echo ""
echo "========================================="
echo "  文件统计"
echo "========================================="
swift_count=$(find iEnvs/ -name "*.swift" | wc -l | tr -d ' ')
echo "Swift 源文件: $swift_count 个"
total_lines=$(find iEnvs/ -name "*.swift" -exec cat {} + | wc -l | tr -d ' ')
echo "总代码行数: $total_lines 行"
echo ""
echo "📖 需求文档: docs/PRD.md"
echo "📐 设计文档: docs/SystemDesign.md"
echo ""
echo "========================================="
