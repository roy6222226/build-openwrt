#!/bin/bash

# =========================================================
# 1. 预置函数定义 (保留原脚本的工具函数)
# =========================================================

color() {
    case $1 in
        cr) echo -e "\e[1;31m$2\e[0m" ;;  # 红色
        cg) echo -e "\e[1;32m$2\e[0m" ;;  # 绿色
        cy) echo -e "\e[1;33m$2\e[0m" ;;  # 黄色
        cb) echo -e "\e[1;34m$2\e[0m" ;;  # 蓝色
        cp) echo -e "\e[1;35m$2\e[0m" ;;  # 紫色
        cc) echo -e "\e[1;36m$2\e[0m" ;;  # 青色
    esac
}

print_info() {
    printf "%s %-40s %s %s %s\n" $1 $2 $3 $4 $5
}

find_dir() {
    find $1 -maxdepth 3 -type d -name $2 -print -quit 2>/dev/null
}

# 核心克隆函数
git_clone() {
    local repo_url branch target_dir current_dir
    if [[ "$1" == */* ]]; then
        repo_url="$1"
        shift
    else
        branch="-b $1 --single-branch"
        repo_url="$2"
        shift 2
    fi
    if [[ -n "$@" ]]; then
        target_dir="$@"
    else
        target_dir="${repo_url##*/}"
    fi
    # 强制克隆到 package/A 下，方便管理
    target_dir="package/A/$target_dir"
    
    git clone -q $branch --depth=1 $repo_url $target_dir 2>/dev/null || {
        print_info $(color cr 拉取) $repo_url [ $(color cr ✕) ]
        return 0
    }
    rm -rf $target_dir/{.git*,README*.md,LICENSE}
    print_info $(color cb 添加) $target_dir [ $(color cb ✔) ]
}

clone_dir() {
    local repo_url branch temp_dir=$(mktemp -d)
    if [[ "$1" == */* ]]; then
        repo_url="$1"
        shift
    else
        branch="-b $1 --single-branch"
        repo_url="$2"
        shift 2
    fi
    git clone -q $branch --depth=1 $repo_url $temp_dir 2>/dev/null
    local target_dir source_dir
    for target_dir in "$@"; do
        source_dir=$(find_dir "$temp_dir" "$target_dir")
        # 移动到 package/A
        if [[ -d $source_dir ]]; then
            mv -f $source_dir package/A/
            print_info $(color cb 添加) $target_dir [ $(color cb ✔) ]
        fi
    done
    rm -rf $temp_dir
}

clone_all() {
    local repo_url branch temp_dir=$(mktemp -d)
    if [[ "$1" == */* ]]; then
        repo_url="$1"
        shift
    else
        branch="-b $1 --single-branch"
        repo_url="$2"
        shift 2
    fi
    git clone -q $branch --depth=1 $repo_url $temp_dir 2>/dev/null
    # 移动该仓库下所有文件夹到 package/A
    cp -rf $temp_dir/* package/A/ 2>/dev/null
    print_info $(color cb 添加) "Whole Repo: $repo_url" [ $(color cb ✔) ]
    rm -rf $temp_dir
}


# =========================================================
# 2. 整合 roy6222226/fanchmwrt 的代码
# =========================================================
echo "正在整合 FanchmWrt 插件..."

TEMP_DIR="/tmp/roy_source"
rm -rf "$TEMP_DIR"
git clone --depth 1 https://github.com/roy6222226/fanchmwrt.git "$TEMP_DIR"

if [ -d "$TEMP_DIR/package" ]; then
    # 使用 cp -rn (不覆盖模式)，只提取 ImmortalWrt 没有的插件
    cp -rn "$TEMP_DIR/package/"* package/
    
    # 🚨🚨🚨 【核心修正步骤】 🚨🚨🚨
