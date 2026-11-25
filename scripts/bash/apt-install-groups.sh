#!/usr/bin/env bash
set -u

CONF_FILE="${CONF_FILE:-apt-groups.conf}"
INSTALL_CMD="${INSTALL_CMD:-sudo apt-get install -yq}"
LOG_DIR="${LOG_DIR:-./logs}"
mkdir -p "$LOG_DIR"

# ---------- 读取分组配置 ----------
declare -A groups
declare -A group_order=()

load_conf() {
    local line g pkgs
    while IFS= read -r line; do
        [[ -z "$line" || "$line" == \#* ]] && continue
        g="${line%%:*}"
        pkgs="${line#*:}"
        # 去掉首尾空格
        g="$(echo "$g" | xargs)"
        pkgs="$(echo "$pkgs" | xargs)"
        [[ -z "$g" ]] && continue
        groups["$g"]="$pkgs"
        group_order+=("$g")
    done < "$CONF_FILE"
}

load_conf
if [[ ${#group_order[@]} -eq 0 ]]; then
    echo "错误：$CONF_FILE 中没有读到任何分组" >&2
    exit 1
fi
if [[ ${#group_order[@]} -gt 10 ]]; then
    echo "警告：分组数量 ${#group_order[@]} 超过 10，菜单仍可用但建议精简" >&2
fi

# ---------- 全局状态 ----------
declare -A installed=()   # 已安装/已处理过的包
declare -A failed=()      # 安装失败的包


install_pkg() {
    local g="$1" pkg="$2"
    if [[ -n "${installed[$pkg]:-}" ]]; then
        echo "  * $pkg 已安装，跳过"
        return 0
    fi
    if $INSTALL_CMD "$pkg" >> "$LOG_DIR/install-$g.log" 2>&1; then
        echo "  ✔ $pkg 安装成功"
        installed["$pkg"]=1
    else
        echo "  ✘ $pkg 安装失败（详见 $LOG_DIR/install-$g.log）"
        failed["$pkg"]=1
    fi
}

# 逐包确认处理一个组
process_group_interactive() {
    local g="$1" pkg ans
    for pkg in ${groups[$g]}; do
        if [[ -n "${installed[$pkg]:-}" ]]; then
            echo "  * $pkg（已安装，自动跳过）"
            continue
        fi
        while true; do
            read -n 1 -p "  安装 $pkg ? [Y/n/q] " ans; echo
            case "${ans:-y}" in
                [Yy]) install_pkg "$g" "$pkg"; break ;;
                [Nn]) echo "  跳过 $pkg"; break ;;
                [Qq]) echo "退出"; exit 0 ;;
                *)    echo "  请输入 y/n/q" ;;
            esac
        done
    done
}

# 整组安装（已装包自动跳过）
process_group_all() {
    local g="$1" pkg
    for pkg in ${groups[$g]}; do
        if [[ -n "${installed[$pkg]:-}" ]]; then
            echo "  * $pkg（已安装，自动跳过）"
        else
            install_pkg "$g" "$pkg"
        fi
    done
}

# ---------- 参数解析 ----------
AUTO_YES=false
CHOSEN_GROUPS=()

while [[ $# -gt 0 ]]; do
    case "$1" in
        --yes|-y) AUTO_YES=true; shift ;;
        --groups)
            IFS=',' read -r -a CHOSEN_GROUPS <<< "$2"
            shift 2 ;;
        --groups=*)
            IFS=',' read -r -a CHOSEN_GROUPS <<< "${1#*=}"
            shift ;;
        -h|--help)
            echo "用法: $0 [--groups g1,g2] [--yes]"
            echo "  分组配置: $CONF_FILE"
            exit 0 ;;
        *) echo "未知参数: $1" >&2; exit 1 ;;
    esac
done

# ---------- 选择要处理的组 ----------
if [[ ${#CHOSEN_GROUPS[@]} -gt 0 ]]; then
    # 校验组名
    for g in "${CHOSEN_GROUPS[@]}"; do
        if [[ -z "${groups[$g]:-}" ]]; then
            echo "错误：未知分组 '$g'" >&2
            exit 1
        fi
    done
else
    echo "可用分组："
    i=1
    for g in "${group_order[@]}"; do
        printf "  %d) %-10s %s\n" "$i" "$g" "${groups[$g]}"
        ((i++))
    done
    echo
    read -p "选择要处理的组（编号，空格分隔，如 1 3；a=全部）: " -a picks
    if [[ "${picks[0]:-}" == "a" || "${picks[0]:-}" == "A" ]]; then
        CHOSEN_GROUPS=("${group_order[@]}")
    else
        for p in "${picks[@]}"; do
            if ! [[ "$p" =~ ^[0-9]+$ ]] || (( p < 1 || p > ${#group_order[@]} )); then
                echo "忽略无效编号: $p"
                continue
            fi
            CHOSEN_GROUPS+=("${group_order[$((p-1))]}")
        done
    fi
fi

if [[ ${#CHOSEN_GROUPS[@]} -eq 0 ]]; then
    echo "未选择任何分组，退出。"
    exit 0
fi

# ---------- 主循环 ----------
for g in "${CHOSEN_GROUPS[@]}"; do
    echo
    echo "=== 分组: $g ==="
    if $AUTO_YES; then
        process_group_all "$g"
        continue
    fi
    read -n 1 -p "整组安装? [Y=整组/n=整组跳/p=逐包确认/q=退出] " ans; echo
    case "${ans:-y}" in
        [Yy]) process_group_all "$g" ;;
        [Nn]) echo "整组跳过 $g" ;;
        [Pp]) process_group_interactive "$g" ;;
        [Qq]) echo "退出"; break ;;
        *)    echo "无效输入，跳过该组" ;;
    esac
done

# ---------- 汇总 ----------
echo
echo "===== 汇总 ====="
echo "已安装/已处理: ${#installed[@]} 个"
if [[ ${#installed[@]} -gt 0 ]]; then
    printf '  %s\n' "${!installed[@]}"
fi
if [[ ${#failed[@]} -gt 0 ]]; then
    echo "安装失败: ${#failed[@]:-0} 个"
    printf '  %s\n' "${!failed[@]}"
    exit 1
fi
echo "全部完成。"
