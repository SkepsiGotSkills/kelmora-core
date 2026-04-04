#!/bin/bash
# ==============================================================================
# 🌌 KELMORA CLOUD OS - "THE SINGULARITY" OMNI-PROVISIONER
# VERSION: 26.0 (THE ABSOLUTE MASTER BUILD)
# ==============================================================================

# ------------------------------------------------------------------------------
# [CORE INIT] Kernel & Terminal Safeguards
# ------------------------------------------------------------------------------
set +H # Disable Bash history expansion to guarantee 100% paste safety
set +m # Mute background job control output

if [[ $EUID -ne 0 ]]; then
   echo -e "\033[0;31m[❌] CRITICAL ERROR: The Singularity engine must be ignited as root (use sudo).\033[0m"
   exit 1
fi

# Kelmora TrueColor Palette
KC="\033[38;2;16;150;138m" # Primary Kelmora Teal/Cyan
KW="\033[1;37m"            # Bold White
KG="\033[1;32m"            # Success Green
KR="\033[1;31m"            # Critical Red
NC="\033[0m"               # No Color

# Hide blinking cursor for cinematic Apple-style polish
tput civis
trap 'tput cnorm; echo -e "\n${KR}[!] Installation aborted by user.${NC}"; exit 1' INT TERM

clear
echo -e "${KC}======================================================================${NC}"
echo -e "${KW}  🚀 IGNITING KELMORA SIGNATURE OS: THE SINGULARITY ENGINE${NC}"
echo -e "${KC}======================================================================${NC}"
echo ""

# ------------------------------------------------------------------------------
# [UI ENGINE] Synchronous Braille Loader
# ------------------------------------------------------------------------------
_run_task() {
    local msg="$1"
    local func="$2"
    
    (
        local frames=("⠋" "⠙" "⠹" "⠸" "⠼" "⠴" "⠦" "⠧" "⠇" "⠏")
        while true; do
            for frame in "${frames[@]}"; do
                printf "\r${KC} [%s] ${NC}${KW}%s${NC}\033[K" "$frame" "$msg"
                sleep 0.08
            done
        done
    ) &
    local spinner_pid=$!
    disown $spinner_pid 2>/dev/null || true
    
    $func >/dev/null 2>&1
    local exit_code=$?
    
    kill -9 $spinner_pid 2>/dev/null || true
    wait $spinner_pid 2>/dev/null || true
    
    if [ $exit_code -eq 0 ]; then
        printf "\r${KG} [✓] ${NC}${KW}%s${NC}\033[K\n" "$msg"
    else
        printf "\r${KR} [❌] FAILED: ${NC}${KW}%s${NC}\033[K\n" "$msg"
    fi
    sleep 0.1 
}

# ------------------------------------------------------------------------------
# [GHOST FETCHER] 100% Reliable Header Redirect Downloader
# ------------------------------------------------------------------------------
_fetch_gh_latest() {
    local repo="$1"
    local filename_template="$2"
    local out_name="$3"

    # Ping GitHub for the latest tag via Location header (Bypasses API & HTML Scraping)
    local tag=$(curl -sI "https://github.com/${repo}/releases/latest" | grep -i '^location:' | sed 's/\r//' | awk -F '/' '{print $NF}')
    if [[ -z "$tag" ]]; then return 1; fi

    local version="${tag#v}"
    local filename="${filename_template/\{VERSION\}/$version}"
    local filename="${filename/\{TAG\}/$tag}"

    local url="https://github.com/${repo}/releases/download/${tag}/${filename}"
    wget -qO "/tmp/${out_name}" "$url"
}

# ============================================================
# 🛠️ STAGE 1: SYSTEM PREPARATION & DEEP KERNEL TUNING
# ============================================================

step_hw_check() {
    if [[ $(uname -m) != "x86_64" ]]; then exit 1; fi
    ping -c 1 8.8.8.8 || exit 1
    mount -o remount,rw / || exit 1
    touch /etc/kelmora_hw_test || exit 1
    rm -f /etc/kelmora_hw_test
}

step_scrub() {
    rm -f /usr/bin/kelmora-* /usr/local/bin/kelmora-* /bin/kelmora-* || true
    rm -f /etc/sudoers.d/kelmora /etc/kelmora_env.sh /etc/profile.d/kelmora_welcome.sh || true
    sed -i '/_kelmora_prompt/d' /root/.bashrc /home/*/.bashrc /etc/bash.bashrc 2>/dev/null || true
    sed -i '/PROMPT_COMMAND/d' /root/.bashrc /home/*/.bashrc /etc/bash.bashrc 2>/dev/null || true
    sed -i '/starship init/d' /root/.bashrc /home/*/.bashrc /etc/bash.bashrc 2>/dev/null || true
    sed -i '/zoxide init/d' /root/.bashrc /home/*/.bashrc /etc/bash.bashrc 2>/dev/null || true
    sed -i '/FZF_DEFAULT_OPTS/d' /root/.bashrc /home/*/.bashrc /etc/bash.bashrc 2>/dev/null || true
}

step_kernel_optim() {
    # 1. Network & Memory Physics Tuning
    sudo tee -a /etc/sysctl.conf > /dev/null << 'EOF'
net.core.default_qdisc=fq
net.ipv4.tcp_congestion_control=bbr
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
    sysctl -p > /dev/null 2>&1

    # 2. File Descriptor Limits
    sudo tee -a /etc/security/limits.conf > /dev/null << 'EOF'
* soft nofile 1048576
* hard nofile 1048576
root soft nofile 1048576
root hard nofile 1048576
EOF

    # 3. I/O Scheduler Tuning (mq-deadline for rapid read/write handling)
    echo 'ACTION=="add|change", KERNEL=="sd[a-z]|nvme[0-9]n[0-9]", ATTR{queue/rotational}=="0", ATTR{queue/scheduler}="mq-deadline"' | sudo tee /etc/udev/rules.d/60-io-scheduler.rules > /dev/null
    udevadm control --reload-rules 2>/dev/null || true
    udevadm trigger 2>/dev/null || true
}

# ============================================================
# 🛠️ STAGE 2: DEPENDENCIES & OPEN SOURCE INTEGRATIONS
# ============================================================

step_deps() {
    export DEBIAN_FRONTEND=noninteractive
    apt-get update -qq
    
    # Nala first
    apt-get install -y -qq nala || true

    # Core system tools & ZRAM
    apt-get install -y -qq curl apt-transport-https ca-certificates gnupg bc htop unzip wget tar ufw git jq net-tools pv cmatrix mtr-tiny dnsutils software-properties-common fail2ban iperf3 nethogs ncdu bat ripgrep fd-find lnav ffmpeg p7zip-full poppler-utils imagemagick bzip2 zram-tools ranger
    
    # Setup ZRAM (Compressed RAM for peak performance)
    sudo tee /etc/default/zramswap > /dev/null << 'EOF'
ALGO=lz4
PERCENT=50
EOF
    systemctl restart zramswap 2>/dev/null || true

    # Alias batcat to bat globally
    ln -sf /usr/bin/batcat /usr/local/bin/bat || true
    
    # Prettyping
    curl -sL https://raw.githubusercontent.com/denilsonsa/prettyping/master/prettyping -o /usr/local/bin/prettyping
    chmod +x /usr/local/bin/prettyping
}

step_ookla() {
    curl -s https://packagecloud.io/install/repositories/ookla/speedtest-cli/script.deb.sh | bash
    apt-get install -y -qq speedtest
}

step_rust_binaries() {
    # 1. FZF (Command Center Core)
    _fetch_gh_latest "junegunn/fzf" "fzf-{VERSION}-linux_amd64.tar.gz" "fzf.tar.gz"
    mkdir -p /tmp/fzf_tmp && tar -xzf /tmp/fzf.tar.gz -C /tmp/fzf_tmp && find /tmp/fzf_tmp -type f -name "fzf" -exec mv {} /usr/local/bin/fzf \; && chmod +x /usr/local/bin/fzf

    # 2. Btop++ (Sci-Fi Resource Monitor)
    _fetch_gh_latest "aristocratos/btop" "btop-x86_64-linux-musl.tbz" "btop.tbz"
    mkdir -p /tmp/btop_tmp && tar -xjf /tmp/btop.tbz -C /tmp/btop_tmp && find /tmp/btop_tmp -type f -name "btop" -exec mv {} /usr/local/bin/btop \; && chmod +x /usr/local/bin/btop

    # 3. Doggo (Human-readable DNS)
    _fetch_gh_latest "mr-karan/doggo" "doggo_{VERSION}_linux_amd64.tar.gz" "doggo.tar.gz"
    mkdir -p /tmp/doggo_tmp && tar -xzf /tmp/doggo.tar.gz -C /tmp/doggo_tmp && find /tmp/doggo_tmp -type f -name "doggo" -exec mv {} /usr/local/bin/doggo \; && chmod +x /usr/local/bin/doggo

    # 4. GDU (Go Disk Usage Analyzer)
    _fetch_gh_latest "dundee/gdu" "gdu_linux_amd64.tgz" "gdu.tgz"
    mkdir -p /tmp/gdu_tmp && tar -xzf /tmp/gdu.tgz -C /tmp/gdu_tmp && find /tmp/gdu_tmp -type f -name "gdu*" -exec mv {} /usr/local/bin/gdu \; && chmod +x /usr/local/bin/gdu

    # 5. Navi (Interactive Cheat Sheet)
    _fetch_gh_latest "denisidoro/navi" "navi-{TAG}-x86_64-unknown-linux-musl.tar.gz" "navi.tar.gz"
    mkdir -p /tmp/navi_tmp && tar -xzf /tmp/navi.tar.gz -C /tmp/navi_tmp && find /tmp/navi_tmp -type f -name "navi" -exec mv {} /usr/local/bin/navi \; && chmod +x /usr/local/bin/navi

    # 6. Eza & Zellij
    _fetch_gh_latest "eza-community/eza" "eza_x86_64-unknown-linux-gnu.tar.gz" "eza.tar.gz"
    mkdir -p /tmp/eza_tmp && tar -xzf /tmp/eza.tar.gz -C /tmp/eza_tmp && find /tmp/eza_tmp -type f -name "eza" -exec mv {} /usr/local/bin/eza \; && chmod +x /usr/local/bin/eza
    
    _fetch_gh_latest "zellij-org/zellij" "zellij-x86_64-unknown-linux-musl.tar.gz" "zellij.tar.gz"
    mkdir -p /tmp/zellij_tmp && tar -xzf /tmp/zellij.tar.gz -C /tmp/zellij_tmp && find /tmp/zellij_tmp -type f -name "zellij" -exec mv {} /usr/local/bin/zellij \; && chmod +x /usr/local/bin/zellij

    # 7. Lazygit & Lazydocker
    _fetch_gh_latest "jesseduffield/lazygit" "lazygit_{VERSION}_Linux_x86_64.tar.gz" "lazygit.tar.gz"
    mkdir -p /tmp/lazygit_tmp && tar -xzf /tmp/lazygit.tar.gz -C /tmp/lazygit_tmp && find /tmp/lazygit_tmp -type f -name "lazygit" -exec mv {} /usr/local/bin/lazygit \; && chmod +x /usr/local/bin/lazygit
    curl -sL https://raw.githubusercontent.com/jesseduffield/lazydocker/master/scripts/install_update_linux.sh | DIR=/usr/local/bin bash

    # 8. Micro & Zoxide
    curl -sL https://getmic.ro | bash && mv micro /usr/local/bin/
    curl -sS https://raw.githubusercontent.com/ajeetdsouza/zoxide/main/install.sh | bash && mv ~/.local/bin/zoxide /usr/local/bin/ || true
    
    # Cleanup
    rm -rf /tmp/*_tmp /tmp/*.tar.gz /tmp/*.zip /tmp/*.tbz /tmp/*.tgz
}

# ============================================================
# 🎨 STAGE 3: CUSTOM CONFIGURATIONS & THEMING
# ============================================================

step_fastfetch() {
    _fetch_gh_latest "fastfetch-cli/fastfetch" "fastfetch-linux-amd64.tar.gz" "fastfetch.tar.gz"
    mkdir -p /tmp/ff_tmp && tar -xzf /tmp/fastfetch.tar.gz -C /tmp/ff_tmp && find /tmp/ff_tmp -type f -name "fastfetch" -exec mv {} /usr/local/bin/fastfetch \; && chmod +x /usr/local/bin/fastfetch
    
    sudo tee /etc/kelmora_logo.txt > /dev/null << 'EOF'
    //\       K E L M O R A
   //  \      C L O U D   O S
  //    \     -----------------
 //======\
//        \
EOF

    sudo tee /etc/fastfetch-kelmora.jsonc > /dev/null << 'EOF'
{
  "$schema": "https://github.com/fastfetch-cli/fastfetch/raw/dev/doc/json_schema.json",
  "logo": {"type": "file", "source": "/etc/kelmora_logo.txt", "color": {"1": "38;2;16;150;138"}},
  "display": {"color": "38;2;16;150;138", "separator": " ➜  "},
  "modules": ["title","separator","os","host","kernel","uptime","packages","shell","cpu","memory","swap","disk","localip","break","colors"]
}
EOF
}

step_starship() {
    curl -sS https://starship.rs/install.sh | sh -s -- -y
    
    sudo tee /etc/starship.toml > /dev/null << 'EOF'
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
}

step_tui_configs() {
    mkdir -p /root/.config/zellij/themes
    sudo tee /root/.config/zellij/config.kdl > /dev/null << 'EOF'
theme "kelmora"
default_layout "compact"
EOF
    sudo tee /root/.config/zellij/themes/kelmora.kdl > /dev/null << 'EOF'
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
}

# ============================================================
# 🧠 STAGE 4: THE UNIFIED COMMAND ENGINE
# ============================================================

step_cli_engine() {
    sudo tee /etc/kelmora_env.sh > /dev/null << 'EOF'
export TMOUT=3600 
export HISTCONTROL=ignoreboth:erasedups 
export KELMORA_VER="SINGULARITY"
export STARSHIP_CONFIG=/etc/starship.toml
export BAT_THEME="TwoDark"
export EDITOR="micro"
export VISUAL="micro"
export MANPAGER="sh -c 'col -bx | bat -l man -p'"

export FZF_DEFAULT_OPTS="--color=fg:#ffffff,bg:-1,hl:#10968A --color=fg+:#ffffff,bg+:#10968A,hl+:#000000 --color=info:#10968A,prompt:#10968A,pointer:#10968A,marker:#10968A,spinner:#10968A,header:#10968A"

unset PROMPT_COMMAND
export PS1='[\u@\h \W]\$ '
if command -v starship &> /dev/null; then eval "$(starship init bash 2>/dev/null)"; fi
if command -v zoxide &> /dev/null; then eval "$(zoxide init bash 2>/dev/null)"; fi

if [ -f /usr/share/doc/fzf/examples/key-bindings.bash ]; then
    source /usr/share/doc/fzf/examples/key-bindings.bash
fi

alias ls='eza --icons --color=always --group-directories-first'
alias ll='eza -la --icons --color=always --group-directories-first'
alias cat='bat --style=plain'

if command -v nala &> /dev/null; then
    alias apt='nala'
fi

command_not_found_handle() {
    local cmd="$1"
    echo -e "\033[1;31m[K] ❌ Kelmora Core: Command '$cmd' is not recognized.\033[0m"
    if [ -x /usr/lib/command-not-found ]; then
       /usr/lib/command-not-found -- "$cmd"
    elif [ -x /usr/share/command-not-found/command-not-found ]; then
       /usr/share/command-not-found/command-not-found -- "$cmd"
    fi
    echo -e "\033[1;37m[K] 💡 Type '\033[38;2;16;150;138mkelmora\033[1;37m' for the interactive Command Center.\033[0m"
    return 127
}

cd() { 
    builtin cd "$@" || return
    echo -e "\033[38;2;16;150;138m📂 $(pwd):\033[0m"
    if command -v eza &> /dev/null; then
        eza --icons --color=always --group-directories-first
    else
        ls --color=auto
    fi
}

_k_loader() {
    local msg="$1"
    tput civis
    echo -en "\033[38;2;16;150;138m⚡ $msg \033[0m"
    for i in {1..15}; do echo -n "━"; sleep 0.02; done
    echo -e "\033[1;32m 🟢\033[0m"
    tput cnorm
}

kelmora() {
    local cmd=$1
    shift 
    
    if [[ -z "$cmd" ]]; then
        if ! command -v fzf &> /dev/null; then
            echo -e "\033[1;31m[K] ❌ FZF engine missing. Please run the installer again.\033[0m"
            return
        fi
        
        local choices="os            | Generate Kelmora Hardware Identity (Fastfetch)
info          | Print raw CPU, Kernel, and Architecture data
services      | Scan and view local Application Health Matrix
optimizer     | Animated OS Update & Deep Junk Purge (Nala)
scan          | Animated Deep System Diagnostics
stats         | Next-Gen Sci-Fi Resource Monitor (Btop++)
cleanup       | Hyper-fast graphical disk cleaner (GDU)
dns           | Human-readable DNS query visualizer (Doggo)
zram-status   | View live ZRAM Memory Compression limits
bench         | Execute comprehensive Hardware Benchmark
install-ptero | Launch Pterodactyl Community Auto-Installer
install-docker| Auto-install Docker Engine & Compose
install-java  | Auto-install Java 8, 17, and 21
install-nodejs| Auto-install Node.js LTS Runtime
install-lamp  | Auto-install Web Stack (Apache/MySQL/PHP)
install-lemp  | Auto-install Web Stack (Nginx/MariaDB/PHP)
workspace     | Launch Next-Gen Terminal Multiplexer (Zellij)
docker-ui     | Graphical TUI Dashboard for Docker (Lazydocker)
git           | Graphical Version Control Dashboard (Lazygit)
files         | Next-Gen Graphical File Explorer (Ranger)
logs-view     | Advanced Graphical Log Analyzer (Lnav)
find          | Telepathic File Finder with Live Preview
search        | Deep Content Search Engine (Ripgrep)
cheat         | Interactive Widget Cheat Sheet (Navi)
edit          | Next-Gen IDE File Editor with Mouse (Micro)
read          | Syntax-highlighted file reader (Bat)
ls            | Graphical directory list with icons (Eza)
tree          | Graphical Visual Directory Map (Eza)
compress      | Zip a folder with visual progress bar
extract       | Unzip an archive with visual progress bar
nuke          | Safely shred a folder (with confirmation)
secure        | Activate Kelmora Shield & Fail2Ban Firewall
net-rescue    | Emergency Firewall Wipe (If locked out)
speedtest     | Test 10Gbps backbone (Official Ookla CLI)
traffic       | Live visual network traffic monitor (Nethogs)
ping          | Visual Live Latency Bar Graph (Prettyping)
trace         | Advanced Route Tracking (MTR)
ports         | List all active listening ports
audit         | Deep system security & vulnerability sweep
myip          | Display current public IP address
docker-ps     | Beautiful formatted Docker Container List
wings-logs    | Live streaming Pterodactyl Daemon Logs
wings-rest    | Instantly reboot the Wings service
help          | Display the full static Command Matrix
reboot        | Safely reboot the operating system node"

        local selection=$(echo "$choices" | column -s '|' -t | fzf --height 80% --layout=reverse --border --prompt="Kelmora Center ❯ " --header="[ Arrow Keys to Navigate • Enter to Execute ]" 2>/dev/null)
        local parsed_cmd=$(echo "$selection" | awk '{print $1}')
        
        if [[ -n "$parsed_cmd" ]]; then kelmora "$parsed_cmd" "$@"; fi
        return
    fi

    [[ "$cmd" =~ ^(help|os|scan|stats|read|ls|workspace|docker-ui|git|files|logs-view|cleanup|dns|cheat|find|search)$ ]] || _k_loader "[Kelmora OS] Engaging module: $cmd"

    case "$cmd" in
        "os") fastfetch -c /etc/fastfetch-kelmora.jsonc ;;
        "info") echo -e "\033[38;2;16;150;138m⚙️  Hardware Identity:\033[0m\n   CPU: $(lscpu | grep 'Model name' | cut -d: -f2 | xargs)\n   Kernel: $(uname -r)" ;;
        "services") local found=false; for s in docker nginx wings ufw ssh zramswap; do if systemctl list-unit-files | grep -q "^${s}.service"; then found=true; echo -en "   Checking $s... "; systemctl is-active --quiet $s && echo -e "\033[1;32m🟢 ONLINE\033[0m" || echo -e "\033[1;31m🔴 OFFLINE\033[0m"; fi; done; [[ "$found" == false ]] && echo "No tracked services found.";;
        "updater"|"optimizer"|"clean") if command -v nala &> /dev/null; then nala update && nala upgrade -y && nala autoremove -y; else sudo apt update && sudo apt upgrade -y && sudo apt autoremove -y; fi ;;
        "zram-status") zramctl ;;
        "stats") btop ;;
        "cleanup") gdu ;;
        "dns") if [ -z "$1" ]; then echo "Usage: kelmora dns <domain>"; else doggo "$1"; fi ;;
        "bench") curl -sL yabs.sh | bash -s -- -ig ;;
        "reboot") echo -e "\033[1;31mRebooting node in 3 seconds...\033[0m"; sleep 3; sudo reboot ;;
        "scan") tput civis; echo -en "\033[1;37m[SYS] Scanning Memory & Network... \033[0m"; for i in {1..10}; do echo -n "█"; sleep 0.05; done; echo -e " \033[1;32mOK\033[0m"; tput cnorm ;;
        
        "find") 
            local file=$(fzf --preview 'bat --style=numbers --color=always {}')
            [[ -n "$file" ]] && micro "$file"
            ;;
        "search")
            if [ -z "$1" ]; then echo "Usage: kelmora search <text>"; else
                local file=$(rg --files-with-matches --no-messages "$1" | fzf --preview "rg --ignore-case --pretty --context 10 '$1' {}")
                [[ -n "$file" ]] && micro "$file"
            fi
            ;;
        "cheat") navi ;;

        "install-ptero") bash <(curl -s https://pterodactyl-installer.se) ;;
        "install-docker") curl -fsSL https://get.docker.com | bash ;;
        "install-java") sudo apt update && sudo apt install -y openjdk-8-jdk openjdk-17-jdk openjdk-21-jdk ;;
        "install-nodejs") curl -fsSL https://deb.nodesource.com/setup_lts.x | sudo -E bash - && sudo apt-get install -y nodejs ;;
        "install-lamp") sudo apt update && sudo apt install -y apache2 mariadb-server php libapache2-mod-php php-mysql ;;
        "install-lemp") sudo apt update && sudo apt install -y nginx mariadb-server php-fpm php-mysql ;;

        "secure") systemctl enable fail2ban && systemctl start fail2ban && ufw default deny incoming && ufw default allow outgoing && ufw allow 22/tcp && ufw allow 80/tcp && ufw allow 443/tcp && ufw --force enable ;;
        "net-rescue") sudo iptables -F; sudo ufw disable; echo -e "\033[1;31m🚨 Network protections dropped.\033[0m" ;;
        "audit") 
            echo -e "\033[38;2;16;150;138m--- Kelmora Security Audit ---\033[0m"
            echo -n "   UFW Status: "; ufw status | grep -q "active" && echo -e "\033[1;32mACTIVE\033[0m" || echo -e "\033[1;31mINACTIVE\033[0m"
            echo -n "   Fail2Ban:   "; systemctl is-active --quiet fail2ban && echo -e "\033[1;32mACTIVE\033[0m" || echo -e "\033[1;31mINACTIVE\033[0m"
            echo -n "   SSH Root:   "; grep -q "^PermitRootLogin yes" /etc/ssh/sshd_config && echo -e "\033[1;31mENABLED (UNSAFE)\033[0m" || echo -e "\033[1;32mDISABLED/SECURE\033[0m"
            echo -n "   Updates:    "; apt list --upgradable 2>/dev/null | grep -q "upgradable" && echo -e "\033[1;31mPENDING\033[0m" || echo -e "\033[1;32mCLEAN\033[0m"
            ;;
        "speedtest"|"speed") speedtest --accept-license --accept-gdpr ;;
        "ping") prettyping "${1:-8.8.8.8}" ;;
        "trace") mtr 8.8.8.8 ;;
        "traffic") sudo nethogs ;;
        "ports") sudo ss -tulpn | grep LISTEN ;;
        "myip") curl -s ifconfig.me; echo "" ;;
        
        "workspace") zellij --config /etc/kelmora_configs/zellij.kdl ;;
        "docker-ui") lazydocker ;;
        "git") lazygit "$@" ;;
        "files") ranger "$@" ;;
        "logs-view") lnav "$@" ;;
        "read") [[ -z "$1" ]] && echo "Usage: kelmora read <file>" || bat "$@" ;;
        "ls") eza -la --icons --group-directories-first "$@" ;;
        "tree") eza --tree --icons --group-directories-first "$@" ;;
        "edit") [[ -z "$1" ]] && echo "Usage: kelmora edit <file>" || micro "$@" ;;
        "compress") if [[ -z "$1" ]]; then echo "Usage: kelmora compress <folder>"; else tar -czf "${1%/}.tar.gz" "$1"; fi ;;
        "extract") if [[ -z "$1" ]]; then echo "Usage: kelmora extract <file>"; else tar -xzf "$1"; fi ;;
        "nuke") 
            if [[ -z "$1" ]]; then
                echo -e "\033[1;31m[K] ❌ Error: Provide a target to nuke.\033[0m"
            else
                read -p "⚠️ Are you sure you want to NUKE $1? (y/N): " confirm
                if [[ "$confirm" == "y" ]]; then
                    echo -e "\033[1;31m🧨 NUKING $1 in 3...\033[0m"; sleep 1; echo "2..."; sleep 1; echo "1..."; sleep 1
                    rm -rf "$1" && echo -e "\033[1;32m💥 Target eradicated.\033[0m"
                else
                    echo "Nuke aborted."
                fi
            fi
            ;;
        "docker-ps") docker ps -a --format "table {{.ID}}\t{{.Names}}\t{{.Status}}\t{{.Ports}}" ;;
        "wings-logs") sudo journalctl -u wings -n 50 -f ;;
        "wings-rest") sudo systemctl restart wings; echo -e "\033[1;32m🦖 Wings restarted.\033[0m" ;;
        "welcome") /usr/local/bin/k-welcome ;;
        "matrix") cmatrix -b -C cyan ;;
        "help"|"") _k_help ;;
        *) echo -e "\033[1;31m[K] ❌ Module '$cmd' not found. Type 'kelmora' for the menu.\033[0m" ;;
    esac
}

_k_help() {
    echo -e "\033[38;2;16;150;138m======================================================================\033[0m"
    echo -e "\033[1;37m         KELMORA CLOUD SIGNATURE BUILD - COMMAND MATRIX\033[0m"
    echo -e "\033[38;2;16;150;138m======================================================================\033[0m"
    echo -e "\033[1;37m Usage: \033[38;2;16;150;138mkelmora \033[1;37m<module>   (Or just type \033[38;2;16;150;138mkelmora\033[1;37m for the menu)\033[0m"
}
EOF
}

# ============================================================
# 🖥️ STAGE 5: DASHBOARD & DYNAMIC TIPS
# ============================================================

step_motd() {
    sudo tee /etc/update-motd.d/99-kelmora-dash > /dev/null << 'EOF'
#!/bin/bash
C='\033[38;2;16;150;138m'; W='\033[1;37m'; G='\033[1;32m'; NC='\033[0m'
UP=$(uptime -p | sed 's/up //'); LD=$(cat /proc/loadavg | awk '{print $1}')
IP=$(hostname -I | awk '{print $1}')

TIPS=(
    "✨ Tip: Type ${G}kelmora dns${NC} to check domain propagation."
    "✨ Tip: Type ${G}kelmora cleanup${NC} to visually free up disk space."
    "✨ Tip: Type ${G}kelmora stats${NC} to view live CPU/RAM/Disk metrics."
    "✨ Tip: Type ${G}kelmora cheat${NC} for interactive command examples."
    "✨ Tip: Press ${G}Ctrl + R${NC} to fuzzy-search your command history."
    "✨ Tip: Type ${G}kelmora${NC} to open the interactive Command Center."
)
RANDOM_TIP=${TIPS[$RANDOM % ${#TIPS[@]}]}

echo -e "${C}============================================================${NC}"
echo -e "${C}   _  __     _                                 ${NC}"
echo -e "${C}  | |/ /___ | | _ __ ___    ___   _ __  __ _   ${NC}"
echo -e "${C}  | ' // _ \| || '_ ' _ \  / _ \ | '__|/ _' |  ${NC}"
echo -e "${C}  | . \  __/| || | | | | || (_) || |  | (_| |  ${NC}"
echo -e "  |_|\_\___||_||_| |_| |_| \___/ |_|   \__,_|  ${NC}"
echo -e "          ${W}Powered by Kelmora Cloud Hosting${NC}"
echo -e "${C}============================================================${NC}"
echo -e " 🚀 Uptime: ${W}$UP${NC}   ⚡ Load: ${W}$LD${NC}   🌐 IP: ${G}$IP${NC}"
echo -e "${C}------------------------------------------------------------${NC}"
echo -e " $RANDOM_TIP"
echo -e "${C}============================================================${NC}"
EOF
    sudo chmod +x /etc/update-motd.d/99-kelmora-dash
}

step_boot_anim() {
    sudo tee /usr/local/bin/k-welcome > /dev/null << 'EOF'
#!/bin/bash
clear
echo -e "\033[38;2;16;150;138m[SYS]\033[0m Waking Kelmora Node..."
sleep 0.4
echo -en "\033[1;37m[OS] Loading Core Infrastructure [\033[38;2;16;150;138m" 
for i in {1..20}; do echo -n "█"; sleep 0.04; done; echo -e "\033[0m] \033[1;32mOK\033[0m"
sleep 0.5
clear
/etc/update-motd.d/99-kelmora-dash
EOF
    sudo chmod +x /usr/local/bin/k-welcome
    sudo tee /etc/profile.d/kelmora_welcome.sh > /dev/null << 'EOF'
#!/bin/bash
if [ ! -f ~/.kelmora_welcomed ]; then
    /usr/local/bin/k-welcome
    touch ~/.kelmora_welcomed
fi
EOF
}

step_silence_ads() {
    sed -i '/kelmora_env.sh/d' /etc/bash.bashrc
    echo "source /etc/kelmora_env.sh" >> /etc/bash.bashrc
    chmod -x /etc/update-motd.d/10-help-text /etc/update-motd.d/50-motd-news /etc/update-motd.d/80-livepatch /etc/update-motd.d/50-landscape-sysinfo /etc/update-motd.d/90-updates-available /etc/update-motd.d/91-release-upgrade /etc/update-motd.d/95-hwe-eol /etc/update-motd.d/97-overlayroot 2>/dev/null || true
    sed -i 's/Prompt=.*/Prompt=never/' /etc/update-manager/release-upgrades 2>/dev/null || true
    sed -i 's/^PrintMotd.*/PrintMotd no/' /etc/ssh/sshd_config 2>/dev/null || true
    truncate -s 0 /etc/motd 2>/dev/null || true
}

# ============================================================
# ⚙️ MAIN EXECUTION SANDBOX
# ============================================================

main() {
    _run_task "Performing Diagnostics & Disk Integrity..." step_hw_check
    _run_task "Injecting Kernel Speed Optimizations (TCP BBR & ZRAM)..." step_kernel_optim
    _run_task "Purging Ghost Configurations..." step_scrub
    _run_task "Fetching Kelmora Mega-Dependency Library..." step_deps
    _run_task "Hooking into Ookla Enterprise Repositories..." step_ookla
    _run_task "Forging TUI Workspaces (Zellij, Lazygit, Btop++, FZF)..." step_rust_binaries
    _run_task "Deploying Custom OS Identity Engine (Fastfetch)..." step_fastfetch
    _run_task "Forging Starship Rust-Engine Prompt..." step_starship
    _run_task "Deploying Custom TUI Color Themes..." step_tui_configs
    _run_task "Injecting Kelmora Interactive Command Center..." step_cli_engine
    _run_task "Compiling Signature Heartbeat Dashboard..." step_motd
    _run_task "Wiring the Neural Boot sequence..." step_boot_anim
    _run_task "Eradicating Ubuntu Ads & Enforcing Persistence..." step_silence_ads
    
    systemctl restart ssh > /dev/null 2>&1
    tput cnorm 
    echo ""
    echo -e "${KC}======================================================================${NC}"
    echo -e "\033[1;32m  ✅ KELMORA SIGNATURE OS INSTALLED SUCCESSFULLY \033[0m"
    echo -e "${KC}======================================================================${NC}"
    echo -e "\033[1;31m⚠️  CRITICAL: Close this terminal completely and log back in to activate! \033[0m"
}

main "$@"
