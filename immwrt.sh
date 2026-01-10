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
    
    # 🚨🚨🚨 【新增的核心修正步骤】 🚨🚨🚨
    # 删除从 FanchmWrt (Master) 误复制进来的不兼容系统核心包
    # 这些包在 23.05 上编译必挂，必须删掉！
    echo "正在清理不兼容的 Master 核心包..."
    rm -rf package/system/apk
    rm -rf package/system/installer
    rm -rf package/base-files
    rm -rf package/kernel
    
    print_info $(color cg 整合) "FanchmWrt Packages (已清理冲突)" [ $(color cg ✔) ]
else
    print_info $(color cr 错误) "FanchmWrt package dir not found" [ $(color cr ✕) ]
fi
rm -rf "$TEMP_DIR"

# =========================================================
# 3. 下载第三方插件 (基于原脚本)
# =========================================================

# 创建统一存放目录
mkdir -p package/A

# 广告过滤 & DNS
clone_dir openwrt-23.05 https://github.com/coolsnowwolf/luci luci-app-adguardhome
clone_all https://github.com/lwb1978/openwrt-gecoosac
clone_dir https://github.com/sirpdboy/luci-app-ddns-go ddns-go luci-app-ddns-go
clone_all https://github.com/sbwml/luci-app-alist
clone_all https://github.com/sbwml/luci-app-mosdns
git_clone https://github.com/sbwml/packages_lang_golang golang

# iStore
clone_all https://github.com/linkease/istore-ui
clone_all https://github.com/linkease/istore luci

# 流量监控
clone_all https://github.com/brvphoenix/luci-app-wrtbwmon
clone_all https://github.com/brvphoenix/wrtbwmon

# 科学上网 (Passwall / OpenClash)
clone_all https://github.com/fw876/helloworld
clone_all https://github.com/Openwrt-Passwall/openwrt-passwall-packages
clone_all https://github.com/Openwrt-Passwall/openwrt-passwall
clone_all https://github.com/Openwrt-Passwall/openwrt-passwall2
clone_dir https://github.com/vernesong/OpenClash luci-app-openclash
clone_all https://github.com/nikkinikki-org/OpenWrt-nikki
clone_all https://github.com/nikkinikki-org/OpenWrt-momo
clone_dir https://github.com/QiuSimons/luci-app-daed daed luci-app-daed
git_clone https://github.com/immortalwrt/homeproxy luci-app-homeproxy

# 主题 (Themes)
git_clone https://github.com/kiddin9/luci-theme-edge
git_clone https://github.com/jerrykuku/luci-theme-argon
git_clone https://github.com/jerrykuku/luci-app-argon-config
git_clone https://github.com/eamonxg/luci-theme-aurora
git_clone https://github.com/eamonxg/luci-app-aurora-config
git_clone https://github.com/sirpdboy/luci-theme-kucat
git_clone https://github.com/sirpdboy/luci-app-kucat-config

# 晶晨宝盒 (Amlogic)
clone_all https://github.com/ophub/luci-app-amlogic
if [ -d "package/A/luci-app-amlogic" ]; then
    sed -i "s|firmware_repo.*|firmware_repo 'https://github.com/$GITHUB_REPOSITORY'|g" package/A/luci-app-amlogic/root/etc/config/amlogic
    # 注意：RELEASE_TAG 在 workflow 环境变量中定义
    sed -i "s|ARMv8|$RELEASE_TAG|g" package/A/luci-app-amlogic/root/etc/config/amlogic
fi


# =========================================================
# 4. 系统设置与个人优化 (基于原脚本)
# =========================================================

# 移动 files 目录 (如果仓库根目录有 files 文件夹，将其移入源码)
# 注意：在 Actions 环境中，files 位于 $GITHUB_WORKSPACE/files，需要复制到当前目录
if [ -d "$GITHUB_WORKSPACE/files" ]; then
    cp -r $GITHUB_WORKSPACE/files files
fi

# 设置固件 rootfs 大小 (通过修改 config)
# 注意：.config 文件此时可能还没生成，我们直接修改目标文件或等待 defconfig
if [ -n "$PART_SIZE" ]; then
    echo "CONFIG_TARGET_ROOTFS_PARTSIZE=$PART_SIZE" >> .config
fi

# 修改默认 IP (非常重要)
# 之前的逻辑有误，这里使用标准的 sed 方式
if [ -n "$IP_ADDRESS" ]; then
    sed -i "s/192.168.1.1/$IP_ADDRESS/g" package/base-files/files/bin/config_generate
fi

# ttyd 免登录
sed -i 's|/bin/login|/bin/login -f root|g' feeds/packages/utils/ttyd/files/ttyd.config

# 设置 root 密码为 password
sed -i 's/root:::0:99999:7:::/root:$1$V4UetPzk$CYXluq4wUazHjmCDBCqXF.::0:99999:7:::/g' package/base-files/files/etc/shadow

# 更改 Argon 主题背景 (如果有图片)
if [ -f "$GITHUB_WORKSPACE/images/bg1.jpg" ]; then
    cp -f $GITHUB_WORKSPACE/images/bg1.jpg feeds/luci/themes/luci-theme-argon/htdocs/luci-static/argon/img/bg1.jpg
fi

# 修复 Makefile 路径引用问题
find package/A -type f -name "Makefile" | xargs sed -i \
    -e 's?\.\./\.\./\(lang\|devel\)?$(TOPDIR)/feeds/packages/\1?' \
    -e 's?\.\./\.\./luci.mk?$(TOPDIR)/feeds/luci/luci.mk?'

# 移除 attendedsysupgrade (防止编译冲突)
find "feeds/luci/collections" -name "Makefile" | while read -r makefile; do
    if grep -q "luci-app-attendedsysupgrade" "$makefile"; then
        sed -i "/luci-app-attendedsysupgrade/d" "$makefile"
    fi
done

# 转换插件语言翻译 (zh-cn -> zh_Hans)
for e in $(ls -d package/A/luci-*/po feeds/luci/applications/luci-*/po 2>/dev/null); do
    if [[ -d $e/zh-cn && ! -d $e/zh_Hans ]]; then
        ln -s zh-cn $e/zh_Hans 2>/dev/null
    elif [[ -d $e/zh_Hans && ! -d $e/zh-cn ]]; then
        ln -s zh_Hans $e/zh-cn 2>/dev/null
    fi
done

# =========================================================
# 5. 生成元数据与收尾 (保留信息生成)
# =========================================================

# 导出一些变量供 Release 使用
# 注意：不要在这里执行 make defconfig，workflow 会在脚本运行后统一执行

# 尝试获取内核版本用于显示
KERNEL_TEST=$(ls target/linux/ipq60xx/Makefile 2>/dev/null)
if [ -n "$KERNEL_TEST" ]; then
    KERNEL_PATCHVER=$(grep -oP 'KERNEL_PATCHVER:=\K[^ ]+' target/linux/ipq60xx/Makefile)
    echo "KERNEL_VERSION=$KERNEL_PATCHVER" >> $GITHUB_ENV
else
    echo "KERNEL_VERSION=Unknown" >> $GITHUB_ENV
fi

# 获取 Commit 信息
if [ -d .git ]; then
    echo "COMMIT_AUTHOR=$(git show -s --date=short --format="作者: %an")" >> $GITHUB_ENV
    echo "COMMIT_DATE=$(git show -s --date=short --format="时间: %ci")" >> $GITHUB_ENV
    echo "COMMIT_MESSAGE=$(git show -s --date=short --format="内容: %s")" >> $GITHUB_ENV
    echo "COMMIT_HASH=$(git show -s --date=short --format="hash: %H")" >> $GITHUB_ENV
fi

# 预下载 OpenClash 内核 (如果有脚本)
if [[ $CLASH_KERNEL =~ amd64|arm64|armv7|armv6|armv5|386 ]]; then
    if [ -f "$GITHUB_WORKSPACE/scripts/preset-clash-core.sh" ]; then
        chmod +x $GITHUB_WORKSPACE/scripts/preset-clash-core.sh
        $GITHUB_WORKSPACE/scripts/preset-clash-core.sh $CLASH_KERNEL
    fi
fi

color cg "IMMWRT.SH 脚本执行完毕！"
