#!/bin/bash

# iEnvs 版本管理脚本
# 用法: ./scripts/version-manager.sh [patch|minor|major|show]

set -e

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 文件路径
CONSTANTS_FILE="iEnvs/Utils/Constants.swift"
PROJECT_FILE="project.yml"
CHANGELOG_FILE="CHANGELOG.md"

# 获取当前版本
get_current_version() {
    grep 'static let appVersion' "$CONSTANTS_FILE" | sed 's/.*"\(.*\)".*/\1/'
}

# 显示当前版本
show_version() {
    local version=$(get_current_version)
    echo -e "${BLUE}当前版本: $version${NC}"
}

# 解析版本号
parse_version() {
    local version=$1
    echo "$version" | tr '.' '\n'
}

# 递增版本号
bump_version() {
    local type=$1
    local current=$2

    local major=$(echo "$current" | cut -d. -f1)
    local minor=$(echo "$current" | cut -d. -f2)
    local patch=$(echo "$current" | cut -d. -f3)

    # 如果没有 patch 版本，默认为 0
    if [ -z "$patch" ]; then
        patch=0
    fi

    case $type in
        major)
            major=$((major + 1))
            minor=0
            patch=0
            ;;
        minor)
            minor=$((minor + 1))
            patch=0
            ;;
        patch)
            patch=$((patch + 1))
            ;;
    esac

    echo "$major.$minor.$patch"
}

# 生成 Build 号 (格式: YYMMDDHHMM)
generate_build_number() {
    date +"%y%m%d%H%M"
}

# 更新 Constants.swift
update_constants() {
    local new_version=$1
    sed -i '' "s/static let appVersion = \"[^\"]*\"/static let appVersion = \"$new_version\"/" "$CONSTANTS_FILE"
    echo -e "${GREEN}✓${NC} 更新 $CONSTANTS_FILE"
}

# 更新 project.yml
update_project_yml() {
    local new_version=$1
    local build_number=$2

    # 检查是否已经存在 MARKETING_VERSION
    if grep -q "MARKETING_VERSION:" "$PROJECT_FILE"; then
        sed -i '' "s/MARKETING_VERSION: \"[^\"]*\"/MARKETING_VERSION: \"$new_version\"/" "$PROJECT_FILE"
    else
        # 在 settings.base 下添加
        sed -i '' "/^settings:/,/^targets:/ { /^  base:/a\\
    MARKETING_VERSION: \"$new_version\"\\
    CURRENT_PROJECT_VERSION: \"$build_number\"
}" "$PROJECT_FILE"
    fi

    echo -e "${GREEN}✓${NC} 更新 $PROJECT_FILE"
}

# 创建/更新 CHANGELOG.md
update_changelog() {
    local new_version=$1
    local change_type=$2
    shift 2
    local changes="$@"

    local today=$(date +"%Y-%m-%d")
    local new_entry="## [$new_version] - $today

"

    if [ -n "$changes" ]; then
        new_entry+="$changes

"
    else
        new_entry+"### 变更
- 版本更新至 $new_version

"
    fi

    if [ -f "$CHANGELOG_FILE" ]; then
        # 在文件顶部添加新版本
        local temp_file=$(mktemp)
        echo "# Changelog

$new_entry$(tail -n +3 "$CHANGELOG_FILE")" > "$temp_file"
        mv "$temp_file" "$CHANGELOG_FILE"
    else
        cat > "$CHANGELOG_FILE" << EOF
# Changelog

$new_entry
EOF
    fi

    echo -e "${GREEN}✓${NC} 更新 $CHANGELOG_FILE"
}

# 重新生成 Xcode 项目
regenerate_project() {
    if command -v xcodegen &> /dev/null; then
        xcodegen generate
        echo -e "${GREEN}✓${NC} 重新生成 Xcode 项目"
    else
        echo -e "${YELLOW}⚠${NC} 未安装 xcodegen，请手动运行: brew install xcodegen && xcodegen generate"
    fi
}

# 主函数
main() {
    local command=${1:-show}

    case $command in
        show)
            show_version
            ;;
        patch|minor|major)
            local current=$(get_current_version)
            local new_version=$(bump_version "$command" "$current")
            local build_number=$(generate_build_number)

            echo -e "${BLUE}准备更新版本...${NC}"
            echo -e "  当前版本: $current"
            echo -e "  新版本:   $new_version"
            echo -e "  Build号:  $build_number"
            echo ""

            read -p "确认更新? (y/n) " -n 1 -r
            echo

            if [[ $REPLY =~ ^[Yy]$ ]]; then
                update_constants "$new_version"
                update_project_yml "$new_version" "$build_number"

                # 收集变更内容
                echo ""
                echo -e "${BLUE}输入变更摘要 (每行一条, 空行结束):${NC}"
                local changes=""
                while IFS= read -r line; do
                    [ -z "$line" ] && break
                    changes+="- $line\n"
                done

                update_changelog "$new_version" "$command" "$changes"
                regenerate_project

                echo ""
                echo -e "${GREEN}✅ 版本已更新至 $new_version${NC}"
                echo ""
                echo -e "${YELLOW}下一步:${NC}"
                echo "  1. 检查变更: git diff"
                echo "  2. 提交变更: git add -A && git commit -m \"chore: bump version to $new_version\""
                echo "  3. 打标签:   git tag -a v$new_version -m \"Release v$new_version\""
            else
                echo -e "${YELLOW}已取消${NC}"
            fi
            ;;
        set)
            if [ -z "$2" ]; then
                echo -e "${RED}错误: 请指定版本号${NC}"
                echo "用法: $0 set <version>"
                exit 1
            fi
            local new_version=$2
            local build_number=$(generate_build_number)

            echo -e "${BLUE}设置版本为: $new_version${NC}"
            update_constants "$new_version"
            update_project_yml "$new_version" "$build_number"
            regenerate_project
            echo -e "${GREEN}✅ 版本已设置为 $new_version${NC}"
            ;;
        *)
            echo "iEnvs 版本管理脚本"
            echo ""
            echo "用法: $0 [show|patch|minor|major|set <version>]"
            echo ""
            echo "命令:"
            echo "  show          显示当前版本"
            echo "  patch         递增 patch 版本 (1.0.0 -> 1.0.1)"
            echo "  minor         递增 minor 版本 (1.0.0 -> 1.1.0)"
            echo "  major         递增 major 版本 (1.0.0 -> 2.0.0)"
            echo "  set <version> 设置指定版本"
            ;;
    esac
}

main "$@"
