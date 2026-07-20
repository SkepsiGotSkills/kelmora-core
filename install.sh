#!/usr/bin/env bash
# shellcheck shell=bash
# ==============================================================================
# 🌌 KELMORA CLOUD OS - THE SINGULARITY ENGINE (MODULAR)
# ==============================================================================

# ------------------------------------------------------------------------------
# [1. STRICT EXECUTION ENVIRONMENT & GLOBAL PATHS]
# ------------------------------------------------------------------------------
set -Eeuo pipefail
IFS=$'\n\t'
umask 022

readonly APP_NAME="Kelmora Cloud OS"
readonly APP_VERSION="28.0.0-Modular"
readonly STATE_DIR="/var/lib/kelmora"
readonly CONFIG_DIR="/etc/kelmora"
readonly MARKER_FILE="${STATE_DIR}/installed-version"

# ------------------------------------------------------------------------------
# [2. TUI COLOR & BRANDING ENGINE]
# ------------------------------------------------------------------------------
KC=$'\033[38;2;16;150;138m' # Primary Kelmora Teal
KW=$'\033[1;37m'            # Bold White
KG=$'\033[1;32m'            # Success Green
KR=$'\033[1;31m'            # Critical Red
KD=$'\033[2m'               # Dim/Faded
NC=$'\033[0m'               # No Color

SPINNER_PID=""

_cleanup_terminal() {
    if [[ -n "${SPINNER_PID}" ]]; then
        kill "${SPINNER_PID}" 2>/dev/null || true
        wait "${SPINNER_PID}" 2>/dev/null || true
    fi
    tput cnorm 2>/dev/null || true
}
trap _cleanup_terminal EXIT
trap 'printf "\n${KR}[!] Operation aborted by user.${NC}\n" >&2; exit 1' INT TERM

# ------------------------------------------------------------------------------
# [3. ANIMATION & LOGGING SYSTEM]
# ------------------------------------------------------------------------------
_start_spinner() {
    local msg=$1
    tput civis 2>/dev/null || true
    (
        local frames=('⠋' '⠙' '⠹' '⠸' '⠼' '⠴' '⠦' '⠧' '⠇' '⠏')
        while :; do
            for frame in "${frames[@]}"; do
                printf "\r${KC} [%s] ${NC}${KW}%s${NC}\033[K" "$frame" "$msg"
                sleep 0.08
            done
        done
    ) &
    SPINNER_PID=$!
}

_stop_spinner() {
    local result=$1 msg=$2
    if [[ -n "${SPINNER_PID}" ]]; then
        kill "${SPINNER_PID}" 2>/dev/null || true
        wait "${SPINNER_PID}" 2>/dev/null || true
        SPINNER_PID=""
    fi
    tput cnorm 2>/dev/null || true
    if [[ ${result} -eq 0 ]]; then
        printf "\r\033[K${KG} [✓] ${NC}${KW}%s${NC}\n" "$msg"
    else
        printf "\r\033[K${KR} [❌] FAILED: ${NC}${KW}%s${NC}\n" "$msg" >&2
    fi
}

_run_task() {
    local msg=$1
    shift
    _start_spinner "${msg}"
    if "$@"; then
        _stop_spinner 0 "${msg}"
    else
        local rc=$?
        _stop_spinner "${rc}" "${msg}"
        return "${rc}"
    fi
}

_banner() {
    clear
    printf "${KC}======================================================================${NC}\n"
    printf "${KW}  🚀 %s - THE SINGULARITY ENGINE (%s)${NC}\n" "${APP_NAME}" "${APP_VERSION}"
    printf "${KC}======================================================================${NC}\n\n"
}

# ------------------------------------------------------------------------------
# [4. ENVIRONMENT DETECTION MODULE]
# ------------------------------------------------------------------------------
_require_root() {
    [[ ${EUID} -eq 0 ]] || { printf "${KR}[❌] Kelmora OS must be ignited as root (sudo).${NC}\n" >&2; exit 1; }
}

_detect_vps() {
    [[ -r /etc/os-release ]] || return 1
    # shellcheck disable=SC1091
    source /etc/os-release
    case "${ID:-}" in
        ubuntu|debian) export K_OS_ID="${ID}" K_OS_VER="${VERSION_ID:-unknown}" ;;
        *) printf "${KR}[❌] Unsupported OS: ${PRETTY_NAME:-unknown}. Kelmora requires Debian or Ubuntu.${NC}\n" >&2; exit 1 ;;
    esac

    export K_ARCH=$(uname -m)
    [[ "${K_ARCH}" == "x86_64" || "${K_ARCH}" == "aarch64" ]] || { printf "${KR}[❌] Unsupported architecture: ${K_ARCH}.${NC}\n" >&2; exit 1; }

    export K_CORES=$(nproc 2>/dev/null || echo 1)
    export K_RAM_KB=$(grep MemTotal /proc/meminfo | awk '{print $2}')
    export K_RAM_GB=$(awk "BEGIN {printf \"%.1f\", ${K_RAM_KB}/1024/1024}")

    if [[ -f "${MARKER_FILE}" ]]; then
        export K_STATE="Upgrading (v$(cat "${MARKER_FILE}"))"
    else
        export K_STATE="Clean Provision"
    fi
}

# ------------------------------------------------------------------------------
# [5. BASE SYSTEM DEPENDENCIES (APT)]
# ------------------------------------------------------------------------------
_install_base_packages() {
    export DEBIAN_FRONTEND=noninteractive
    apt-get update -qq >/dev/null 2>&1

    local core_deps=(ca-certificates curl wget gnupg jq tar unzip bc software-properties-common)
    local sys_deps=(htop ufw git net-tools pv mtr-tiny dnsutils fail2ban iperf3 nethogs ncdu bat ripgrep fd-find lnav p7zip-full zram-tools ranger)

    apt-get install -y -qq --no-install-recommends "${core_deps[@]}" "${sys_deps[@]}" >/dev/null 2>&1

    if command -v batcat >/dev/null 2>&1; then
        ln -sf /usr/bin/batcat /usr/local/bin/bat
    fi
}

# ------------------------------------------------------------------------------
# [6. THE GITHUB API ENGINE (RUST/GO BINARIES)]
# ------------------------------------------------------------------------------
_fetch_gh_binary() {
    local repo="$1" bin_name="$2" asset_pattern_x86="$3" asset_pattern_arm="$4"
    local asset_pattern

    if [[ "${K_ARCH}" == "x86_64" ]]; then asset_pattern="${asset_pattern_x86}"
    elif [[ "${K_ARCH}" == "aarch64" ]]; then asset_pattern="${asset_pattern_arm}"
    else return 1; fi

    local tag
    tag=$(curl -s "https://api.github.com/repos/${repo}/releases/latest" | jq -r '.tag_name')
    [[ -z "$tag" || "$tag" == "null" ]] && return 1 

    local version="${tag#v}"
    local filename="${asset_pattern/\{VERSION\}/$version}"
    filename="${filename/\{TAG\}/$tag}"

    local download_url="https://github.com/${repo}/releases/download/${tag}/${filename}"
    local tmp_dir="/tmp/kelmora_bins_${bin_name}"
    local archive_path="/tmp/${bin_name}_archive"

    wget -qO "${archive_path}" "${download_url}" || return 1

    mkdir -p "${tmp_dir}"
    if [[ "${filename}" == *.tar.gz || "${filename}" == *.tgz ]]; then tar -xzf "${archive_path}" -C "${tmp_dir}"
    elif [[ "${filename}" == *.tbz || "${filename}" == *.tar.bz2 ]]; then tar -xjf "${archive_path}" -C "${tmp_dir}"
    elif [[ "${filename}" == *.zip ]]; then unzip -q "${archive_path}" -d "${tmp_dir}"
    fi

    find "${tmp_dir}" -type f -name "${bin_name}" -exec install -m 0755 {} /usr/local/bin/ \;
    rm -rf "${tmp_dir}" "${archive_path}"
}

_install_nextgen_ui() {
    _fetch_gh_binary "junegunn/fzf" "fzf" "fzf-{VERSION}-linux_amd64.tar.gz" "fzf-{VERSION}-linux_arm64.tar.gz"
    _fetch_gh_binary "aristocratos/btop" "btop" "btop-x86_64-linux-musl.tbz" "btop-aarch64-linux-musl.tbz"
    _fetch_gh_binary "eza-community/eza" "eza" "eza_x86_64-unknown-linux-gnu.tar.gz" "eza_aarch64-unknown-linux-gnu.tar.gz"
    _fetch_gh_binary "zellij-org/zellij" "zellij" "zellij-x86_64-unknown-linux-musl.tar.gz" "zellij-aarch64-unknown-linux-musl.tar.gz"
    _fetch_gh_binary "zyedidia/micro" "micro" "micro-{VERSION}-linux64.tar.gz" "micro-{VERSION}-linux-arm64.tar.gz"
    _fetch_gh_binary "starship/starship" "starship" "starship-x86_64-unknown-linux-musl.tar.gz" "starship-aarch64-unknown-linux-musl.tar.gz"
    _fetch_gh_binary "fastfetch-cli/fastfetch" "fastfetch" "fastfetch-linux-amd64.tar.gz" "fastfetch-linux-aarch64.tar.gz"
}

# ------------------------------------------------------------------------------
# [7. DEEP KERNEL & NETWORK PHYSICS]
# ------------------------------------------------------------------------------
_apply_system_tuning() {
    if command -v zramctl >/dev/null 2>&1; then
        cat << 'EOF' > /etc/default/zramswap
ALGO=lz4
PERCENT=50
EOF
        systemctl restart zramswap 2>/dev/null || true
    fi

    local bbr_enabled=""
    if sysctl net.ipv4.tcp_available_congestion_control 2>/dev/null | grep -qw bbr; then
        bbr_enabled="net.ipv4.tcp_congestion_control=bbr"
    fi

    cat << EOF > /etc/sysctl.d/99-kelmora.conf
net.core.default_qdisc=fq
${bbr_enabled}
net.ipv4.tcp_fastopen=3
net.core.optmem_max=65536
net.core.rmem_max=16777216
net.core.wmem_max=16777216
net.ipv4.tcp_rmem=4096 87380 16777216
net.ipv4.tcp_wmem=4096 65536 16777216
net.ipv4.tcp_max_syn_backlog=8192
net.ipv4.tcp_max_tw_buckets=5000
net.ipv4.tcp_mtu_probing=1
vm.swappiness=10
vm.dirty_ratio=10
vm.dirty_background_ratio=5
EOF
    sysctl --system > /dev/null 2>&1

    cat << 'EOF' > /etc/security/limits.d/kelmora.conf
* soft nofile 1048576
* hard nofile 1048576
root soft nofile 1048576
root hard nofile 1048576
EOF
}

# ------------------------------------------------------------------------------
# [8. THE KELMORA VISUAL IDENTITY]
# ------------------------------------------------------------------------------
_deploy_visual_identity() {
    install -d -m 0755 "${CONFIG_DIR}"
    install -d -m 0755 "${CONFIG_DIR}/zellij/themes"

    cat << 'EOF' > "${CONFIG_DIR}/starship.toml"
add_newline = false
command_timeout = 1000
format = "$time$custom$username$hostname$directory$git_branch$git_status$nodejs$java$python$cmd_duration$character"
[time]
disabled = false
time_format = "%T"
format = '[\[$time\]](#10968A) [\[K\]](bold #10968A) '
[username]
show_always = true
style_user = "bold white"
style_root = "bold white"
format = "[$user]($style)"
[hostname]
ssh_only = false
style = "bold white"
format = "@[$hostname]($style):"
[directory]
style = "bold #10968A"
read_only = " 🔒"
truncate_to_repo = true
format = "[$path]($style)"
[character]
success_symbol = "[❯](bold white) "
error_symbol = "[❌ ❯](bold red) "
[cmd_duration]
min_time = 2000
format = "took [$duration](#10968A) "
EOF

    cat << 'EOF' > "${CONFIG_DIR}/zellij/config.kdl"
theme "kelmora"
default_layout "compact"
EOF

    cat << 'EOF' > "${CONFIG_DIR}/zellij/themes/kelmora.kdl"
themes {
    kelmora {
        fg "#ffffff"
        bg "#000000"
        black "#000000"
        red "#ff5555"
        green "#50fa7b"
        yellow "#f1fa8c"
        blue "#10968A"
        magenta "#ff79c6"
        cyan "#10968A"
        white "#ffffff"
        orange "#ffb86c"
    }
}
EOF

    cat << 'EOF' > "${CONFIG_DIR}/logo.txt"
    //\       K E L M O R A
   //  \      C L O U D   O S
  //    \     -----------------
 //======\
//        \
EOF

    cat << 'EOF' > "${CONFIG_DIR}/fastfetch.jsonc"
{
  "$schema": "https://github.com/fastfetch-cli/fastfetch/raw/dev/doc/json_schema.json",
  "logo": {"type": "file", "source": "/etc/kelmora/logo.txt", "color": {"1": "38;2;16;150;138"}},
  "display": {"color": "38;2;16;150;138", "separator": " ➜  "},
  "modules": ["title", "separator", "os", "host", "kernel", "uptime", "packages", "shell", "cpu", "memory", "swap", "disk", "localip", "break", "colors"]
}
EOF
}

# ------------------------------------------------------------------------------
# [9. THE MOTD LOGIN DASHBOARD]
# ------------------------------------------------------------------------------
_deploy_motd() {
    chmod -x /etc/update-motd.d/10-help-text /etc/update-motd.d/50-motd-news \
             /etc/update-motd.d/80-livepatch /etc/update-motd.d/50-landscape-sysinfo \
             /etc/update-motd.d/90-updates-available /etc/update-motd.d/91-release-upgrade \
             /etc/update-motd.d/95-hwe-eol /etc/update-motd.d/97-overlayroot 2>/dev/null || true
    sed -i 's/Prompt=.*/Prompt=never/' /etc/update-manager/release-upgrades 2>/dev/null || true
    sed -i 's/^PrintMotd.*/PrintMotd no/' /etc/ssh/sshd_config 2>/dev/null || true
    > /etc/motd

    cat << 'EOF' > /etc/update-motd.d/99-kelmora-dash
#!/usr/bin/env bash
C='\033[38;2;16;150;138m'; W='\033[1;37m'; G='\033[1;32m'; NC='\033[0m'
UP=$(uptime -p 2>/dev/null | sed 's/^up //'); LD=$(cat /proc/loadavg 2>/dev/null | awk '{print $1}')
IP=$(hostname -I 2>/dev/null | awk '{print $1}')
printf "${C}============================================================${NC}\n"
printf "${C}   _  __     _                                 ${NC}\n"
printf "${C}  | |/ /___ | | _ __ ___    ___   _ __  __ _   ${NC}\n"
printf "${C}  | ' // _ \\| || '_ ' _ \\  / _ \\ | '__|/ _' |  ${NC}\n"
printf "${C}  | . \\  __/| || | | | | || (_) || |  | (_| |  ${NC}\n"
printf "${NC}  |_|\\_\\___||_||_| |_| |_| \\___/ |_|   \\__,_|  ${NC}\n"
printf "          ${W}Powered by Kelmora Cloud Hosting${NC}\n"
printf "${C}============================================================${NC}\n"
printf " 🚀 Uptime: ${W}%s${NC}   ⚡ Load: ${W}%s${NC}   🌐 IP: ${G}%s${NC}\n" "$UP" "$LD" "$IP"
printf "${C}============================================================${NC}\n"
printf " ✨ Tip: Type ${W}kelmora${NC} to open the interactive Command Center.\n\n"
EOF
    chmod +x /etc/update-motd.d/99-kelmora-dash
}

# ------------------------------------------------------------------------------
# [10. CLI ENGINE & ENVIRONMENT]
# ------------------------------------------------------------------------------
_deploy_cli_engine() {
    cat << 'EOF' > /etc/profile.d/kelmora.sh
export EDITOR="micro"
export VISUAL="micro"
export BAT_THEME="TwoDark"
export FZF_DEFAULT_OPTS="--color=fg:#ffffff,bg:-1,hl:#10968A --color=fg+:#ffffff,bg+:#10968A,hl+:#000000 --color=info:#10968A,prompt:#10968A,pointer:#10968A,marker:#10968A,spinner:#10968A,header:#10968A"

if command -v starship >/dev/null 2>&1; then
    export STARSHIP_CONFIG="/etc/kelmora/starship.toml"
    eval "$(starship init bash)"
fi

if command -v eza >/dev/null 2>&1; then
    alias ls='eza --icons --color=always --group-directories-first'
    alias ll='eza -la --icons --color=always --group-directories-first'
    alias tree='eza --tree --icons --group-directories-first'
fi
EOF
    chmod 0644 /etc/profile.d/kelmora.sh

    cat << 'EOF' > /usr/local/bin/kelmora
#!/usr/bin/env bash
set -euo pipefail

_have() { command -v "$1" >/dev/null 2>&1; }

_menu() {
    if ! _have fzf; then
        printf "\033[1;31m[❌] Interactive menu requires FZF. Run: sudo kelmora update\033[0m\n" >&2
        return 1
    fi

    local choices="os            | Generate Kelmora Hardware Identity
status        | View Local System Health & Tool Status
stats         | Next-Gen Sci-Fi Resource Monitor (Btop++)
files         | Interactive Graphical File Explorer (Ranger)
logs          | Advanced Log Analyzer (Lnav)
dns           | DNS query visualizer
bench         | Execute comprehensive Hardware Benchmark
workspace     | Launch Terminal Multiplexer (Zellij)
audit         | Deep system security vulnerability sweep
speedtest     | Test 1Gbps/10Gbps backbone
ports         | List all active listening ports
exit          | Close Kelmora Center"

    local selection
    selection=$(printf "%s" "$choices" | column -s '|' -t | fzf --height 75% --layout=reverse --border --prompt="Kelmora Center ❯ " --header="[ Arrow Keys to Navigate • Enter to Execute ]" 2>/dev/null) || return 0
    local cmd
    cmd=$(printf "%s" "$selection" | awk '{print $1}')
    
    [[ -n "$cmd" && "$cmd" != "exit" ]] && exec kelmora "$cmd"
}

case "${1:-menu}" in
    menu) _menu ;;
    os) if _have fastfetch; then exec fastfetch -c /etc/kelmora/fastfetch.jsonc; fi ;;
    status) printf "\033[1;32mKelmora OS Engine Online.\033[0m\nArchitecture: $(uname -m) | Kernel: $(uname -r)\n" ;;
    stats) if _have btop; then exec btop; else printf "btop not installed.\n"; fi ;;
    files) if _have ranger; then exec ranger; fi ;;
    logs) if _have lnav; then exec lnav; fi ;;
    workspace) if _have zellij; then exec zellij --config /etc/kelmora/zellij/config.kdl; fi ;;
    ports) ss -tulpn | grep LISTEN ;;
    dns) [[ $# -ge 2 ]] && dig "$2" || printf "Usage: kelmora dns <domain>\n" ;;
    bench) curl -sL yabs.sh | bash -s -- -ig ;;
    audit) ufw status 2>/dev/null; systemctl is-active --quiet fail2ban && echo "Fail2Ban: ACTIVE" || echo "Fail2Ban: INACTIVE" ;;
    speedtest) if _have speedtest; then speedtest; else printf "speedtest not installed.\n"; fi ;;
    *) printf "\033[1;31m[❌] Unknown command: %s\033[0m\n" "$1" >&2; exit 1 ;;
esac
EOF
    chmod 0755 /usr/local/bin/kelmora
}

# ------------------------------------------------------------------------------
# [11. EXECUTION PIPELINE & STATE MANAGEMENT]
# ------------------------------------------------------------------------------
_perform_install() {
    printf "\n${KC}--- [ IGNITING THE SINGULARITY ] -------------------------------------${NC}\n"
    _run_task "Synchronizing APT Repositories & Base Dependencies" _install_base_packages
    _run_task "Pulling Modern Architecture Binaries via GitHub API" _install_nextgen_ui
    _run_task "Injecting Kernel Physics (BBR) & File Descriptor Limits" _apply_system_tuning
    _run_task "Deploying Kelmora TUI Identity (Starship, Zellij)" _deploy_visual_identity
    _run_task "Compiling Signature Heartbeat Dashboard" _deploy_motd
    _run_task "Hooking Command Center Engine" _deploy_cli_engine
    
    install -d -m 0755 "${STATE_DIR}"
    printf "%s\n" "${APP_VERSION}" > "${MARKER_FILE}"
    
    printf "\n${KC}======================================================================${NC}\n"
    printf "${KG}  ✅ KELMORA SIGNATURE OS DEPLOYED SUCCESSFULLY ${NC}\n"
    printf "${KC}======================================================================${NC}\n"
    printf "${KW}  Run \033[1;32msource /etc/profile.d/kelmora.sh\033[1;37m or restart your SSH session.\n"
    printf "${KW}  Type \033[38;2;16;150;138mkelmora\033[1;37m to access the Command Center.${NC}\n\n"
}

_perform_uninstall() {
    printf "\n${KR}--- [ ENGAGING CLEANUP PROTOCOL ] ------------------------------------${NC}\n"
    _run_task "Scrubbing Kelmora API Binaries" "rm -f /usr/local/bin/fzf /usr/local/bin/btop /usr/local/bin/eza /usr/local/bin/zellij /usr/local/bin/micro /usr/local/bin/starship /usr/local/bin/fastfetch /usr/local/bin/kelmora"
    _run_task "Purging Visual Identity & Global Profiles" "rm -rf /etc/kelmora /etc/profile.d/kelmora.sh"
    _run_task "Reverting MOTD Dashboard to Default State" "rm -f /etc/update-motd.d/99-kelmora-dash && chmod +x /etc/update-motd.d/* 2>/dev/null || true"
    _run_task "Restoring Kernel & Network Physics Defaults" "rm -f /etc/sysctl.d/99-kelmora.conf /etc/security/limits.d/kelmora.conf && sysctl --system >/dev/null 2>&1 || true"
    _run_task "Deleting Provisioner State Metadata" "rm -rf ${STATE_DIR}"
    
    printf "\n${KG}  🧹 SYSTEM RESTORED. Kelmora OS extensions have been cleanly purged.${NC}\n\n"
}

# ------------------------------------------------------------------------------
# [12. THE ONBOARDING TUI (MAIN ENTRY POINT)]
# ------------------------------------------------------------------------------
_onboarding_ui() {
    _banner
    printf "${KD}  Analyzing Target Infrastructure...${NC}\n\n"
    _run_task "Verifying Root Privileges" _require_root
    _run_task "Mapping System Architecture & OS Profile" _detect_vps
    
    printf "\n${KC}--- [ INFRASTRUCTURE PROFILE ] ---------------------------------------${NC}\n"
    printf "  ${KW}Operating System :${NC} %s %s\n" "${K_OS_ID^}" "${K_OS_VER}"
    printf "  ${KW}Architecture     :${NC} %s\n" "${K_ARCH}"
    printf "  ${KW}Compute Power    :${NC} %s Cores, %s GB RAM\n" "${K_CORES}" "${K_RAM_GB}"
    printf "  ${KW}Engine State     :${NC} %s\n" "${K_STATE}"
    printf "${KC}----------------------------------------------------------------------${NC}\n\n"

    printf "  Please select an operations protocol:\n\n"
    printf "  ${KG}[1]${NC} Ignite The Singularity (Install/Update Core System)\n"
    printf "  ${KR}[2]${NC} Engage Cleanup Protocol (Uninstall Kelmora)\n"
    printf "  ${KW}[0]${NC} Abort\n\n"

    tput cnorm
    local choice
    read -r -p "  ❯ " choice
    tput civis

    case "${choice}" in
        1) _perform_install ;;
        2) _perform_uninstall ;;
        0) printf "\n${KW}Abort acknowledged.${NC}\n"; exit 0 ;;
        *) printf "\n${KR}[❌] Invalid input.${NC}\n"; exit 1 ;;
    esac
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    _onboarding_ui
fi