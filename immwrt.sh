#!/bin/bash

# =========================================================
# 1. 预置函数定义
# =========================================================

color() {
    case $1 in
        cr) echo -e "\e[1;31m$2\e[0m" ;;
        cg) echo -e "\e[1;32m$2\e[0m" ;;
        cy) echo -e "\e[1;33m$2\e[0m" ;;
        cb) echo -e "\e[1;34m$2\e[0m" ;;
        cp) echo -e "\e[1;35m$2\e[0m" ;;
        cc) echo -e "\e[1;36m$2\e[0m" ;;
    esac
}

print_info() {
    printf "%s %-40s %s %s %s\n" $1 $2 $3 $4 $5
}

find_dir() {
    find $1 -maxdepth 3 -type d -name $2 -print -quit 2>/dev/null
}

git_clone() {
    local repo_url branch target_dir
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
    cp -rf $temp_dir/* package/A/ 2>/dev/null
    print_info $(color cb 添加) "Whole Repo: $repo_url" [ $(color cb ✔) ]
    rm -rf $temp_dir
}


# =========================================================
# 2. 整合 FanchmWrt 代码 (严格过滤版)
# =========================================================
echo "正在整合 FanchmWrt 插件..."

TEMP_DIR="/tmp/roy_source"
rm -rf "$TEMP_DIR"
git clone --depth 1 https://github.com/roy6222226/fanchmwrt.git "$TEMP_DIR"

if [ -d "$TEMP_DIR/package" ]; then
    # ---------------------------------------------------------
    # 🛡️ 净化步骤：在复制前，彻底删除不兼容的 Master 系统组件
    # ---------------------------------------------------------
    echo "执行排毒操作：剔除不兼容的 Master 核心包..."
    
    rm -rf "$TEMP_DIR/package/base-files"      # 防止 IP/网络配置冲突
    rm -rf "$TEMP_DIR/package/kernel"          # 防止内核版本冲突
    rm -rf "$TEMP_DIR/package/system"          # 彻底移除 apk/procd 等核心
    rm -rf "$TEMP_DIR/package/boot"            # 移除引导相关
    rm -rf "$TEMP_DIR/package/libs/toolchain"  # 🔥 关键：移除导致报错的工具链
    rm -rf "$TEMP_DIR/package/network"         # 建议移除网络底层，防止 firewall4 冲突
    
    # ---------------------------------------------------------
    # 📋 复制剩余内容 (主要是应用插件)
    # ---------------------------------------------------------
    # cp -rn : 递归复制，不覆盖已存在的文件
    cp -rn "$TEMP_DIR/package/"* package/
    
    print_info $(color cg 整合) "FanchmWrt Packages (净化完成)" [ $(color cg ✔) ]
else
    print_info $(color cr 错误) "FanchmWrt package dir not found" [ $(color cr ✕) ]
fi
rm -rf "$TEMP_DIR"


# =========================================================
# 3. 下载第三方插件
# =========================================================

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

# 科学上网
clone_all https://github.com/fw876/helloworld
clone_all https://github.com/Openwrt-Passwall/openwrt-passwall-packages
clone_all https://github.com/Openwrt-Passwall/openwrt-passwall
clone_all https://github.com/Openwrt-Passwall/openwrt-passwall2
clone_dir https://github.com/vernesong/OpenClash luci-app-openclash
clone_all https://github.com/nikkinikki-org/OpenWrt-nikki
clone_all https://github.com/nikkinikki-org/OpenWrt-momo
clone_dir https://github.com/QiuSimons/luci-app-daed daed luci-app-daed
git_clone https://github.com/immortalwrt/homeproxy luci-app-homeproxy

# 主题
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
    sed -i "s|ARMv8|$RELEASE_TAG|g" package/A/luci-app-amlogic/root/etc/config/amlogic
fi

# =========================================================
# 4. 系统设置与个人优化
# =========================================================

if [ -d "$GITHUB_WORKSPACE/files" ]; then
    cp -r $GITHUB_WORKSPACE/files files
fi

if [ -n "$PART_SIZE" ]; then
    echo "CONFIG_TARGET_ROOTFS_PARTSIZE=$PART_SIZE" >> .config
fi

# 修改默认 IP
if [ -n "$IP_ADDRESS" ]; then
    # 这里的路径是 23.05 的标准路径，因为我们没删 base-files，所以一定存在
    sed -i "s/192.168.1.1/$IP_ADDRESS/g" package/base-files/files/bin/config_generate
fi

# ttyd 免登录
sed -i 's|/bin/login|/bin/login -f root|g' feeds/packages/utils/ttyd/files/ttyd.config

# root 密码
sed -i 's/root:::0:99999:7:::/root:$1$V4UetPzk$CYXluq4wUazHjmCDBCqXF.::0:99999:7:::/g' package/base-files/files/etc/shadow

# 背景图
if [ -f "$GITHUB_WORKSPACE/images/bg1.jpg" ]; then
    cp -f $GITHUB_WORKSPACE/images/bg1.jpg feeds/luci/themes/luci-theme-argon/htdocs/luci-static/argon/img/bg1.jpg
fi

# 修复 Makefile
find package/A -type f -name "Makefile" | xargs sed -i \
    -e 's?\.\./\.\./\(lang\|devel\)?$(TOPDIR)/feeds/packages/\1?' \
    -e 's?\.\./\.\./luci.mk?$(TOPDIR)/feeds/luci/luci.mk?'

# 移除 attendedsysupgrade
find "feeds/luci/collections" -name "Makefile" | while read -r makefile; do
    if grep -q "luci-app-attendedsysupgrade" "$makefile"; then
        sed -i "/luci-app-attendedsysupgrade/d" "$makefile"
    fi
done

# 语言转换
for e in $(ls -d package/A/luci-*/po feeds/luci/applications/luci-*/po 2>/dev/null); do
    if [[ -d $e/zh-cn && ! -d $e/zh_Hans ]]; then
        ln -s zh-cn $e/zh_Hans 2>/dev/null
    elif [[ -d $e/zh_Hans && ! -d $e/zh-cn ]]; then
        ln -s zh_Hans $e/zh-cn 2>/dev/null
    fi
done

# =========================================================
# 5. 生成元数据与收尾
# =========================================================

KERNEL_TEST=$(ls target/linux/ipq60xx/Makefile 2>/dev/null)
if [ -n "$KERNEL_TEST" ]; then
    KERNEL_PATCHVER=$(grep -oP 'KERNEL_PATCHVER:=\K[^ ]+' target/linux/ipq60xx/Makefile)
    echo "KERNEL_VERSION=$KERNEL_PATCHVER" >> $GITHUB_ENV
else
    echo "KERNEL_VERSION=Unknown" >> $GITHUB_ENV
fi

if [ -d .git ]; then
    echo "COMMIT_AUTHOR=$(git show -s --date=short --format="作者: %an")" >> $GITHUB_ENV
    echo "COMMIT_DATE=$(git show -s --date=short --format="时间: %ci")" >> $GITHUB_ENV
    echo "COMMIT_MESSAGE=$(git show -s --date=short --format="内容: %s")" >> $GITHUB_ENV
    echo "COMMIT_HASH=$(git show -s --date=short --format="hash: %H")" >> $GITHUB_ENV
fi

if [[ $CLASH_KERNEL =~ amd64|arm64|armv7|armv6|armv5|386 ]]; then
    if [ -f "$GITHUB_WORKSPACE/scripts/preset-clash-core.sh" ]; then
        chmod +x $GITHUB_WORKSPACE/scripts/preset-clash-core.sh
        $GITHUB_WORKSPACE/scripts/preset-clash-core.sh $CLASH_KERNEL
    fi
fi

color cg "IMMWRT.SH 脚本执行完毕！"
