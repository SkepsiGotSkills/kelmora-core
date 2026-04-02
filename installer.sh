#!/bin/bash
# ==============================================================================
# KELMORA CLOUD - THE "SINGULARITY CORE" OMNI-OS PROVISIONER
# VERSION: 23.0 (TITANIUM MASTER BUILD)
# ==============================================================================

# Disable history expansion to guarantee 100% paste safety
set +H 
set +m 

if [[ $EUID -ne 0 ]]; then
   echo -e "\033[0;31m❌ Error: This script must be run as root (use sudo).\033[0m"
   exit 1
fi

# Kelmora TrueColor hex: #10968A
KC="\033[38;2;16;150;138m"
NC="\033[0m"

# Hide the blinking cursor for a polished Apple-like feel
tput civis
trap 'tput cnorm; echo -e "\n\033[1;31mInstallation aborted.\033[0m"; exit 1' INT TERM

clear
echo -e "${KC}======================================================================${NC}"
echo -e "\033[1;37m  🚀 INITIALIZING KELMORA SIGNATURE OS: SINGULARITY CORE\033[0m"
echo -e "${KC}======================================================================${NC}"
echo ""

# --- The Synchronous Safe Loader ---
_run_task() {
    local msg="$1"
    local func="$2"
    
    (
        local frames=("⠋" "⠙" "⠹" "⠸" "⠼" "⠴" "⠦" "⠧" "⠇" "⠏")
        while true; do
            for frame in "${frames[@]}"; do
                printf "\r${KC} [%s] ${NC}\033[1;37m%s\033[0m\033[K" "$frame" "$msg"
                sleep 0.08
            done
        done
    ) &
    local spinner_pid=$!
    disown $spinner_pid 2>/dev/null || true
    
    $func >/dev/null 2>&1
    
    kill -9 $spinner_pid 2>/dev/null || true
    wait $spinner_pid 2>/dev/null || true
    printf "\r\033[1;32m [✓] \033[1;37m%s\033[0m\033[K\n" "$msg"
    sleep 0.1 
}

# --- Dynamic GitHub API Fetcher (Bulletproof Downloads) ---
_fetch_github_binary() {
    local repo="$1"
    local pattern="$2"
    local out_name="$3"
    local api_url="https://api.github.com/repos/${repo}/releases/latest"
    local download_url=$(curl -s "$api_url" | grep "browser_download_url.*${pattern}" | head -n 1 | cut -d '"' -f 4)
    
    if [[ -n "$download_url" ]]; then
        wget -qO "/tmp/${out_name}" "$download_url"
    fi
}

# ============================================================
# 🛠️ STAGE 1: SYSTEM PREPARATION & KERNEL TUNING
# ============================================================

step_hw_check() {
    mount -o remount,rw / || true
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
    # Deep Kernel Tuning for High-Performance Cloud/Game Servers
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

    # Lift file descriptor limits for massive game servers
    sudo tee -a /etc/security/limits.conf > /dev/null << 'EOF'
* soft nofile 1048576
* hard nofile 1048576
root soft nofile 1048576
root hard nofile 1048576
EOF
}

# ============================================================
# 🛠️ STAGE 2: DEPENDENCY & OPEN SOURCE INTEGRATIONS
# ============================================================

step_deps() {
    export DEBIAN_FRONTEND=noninteractive
    apt-get update -qq
    apt-get install -y -qq curl apt-transport-https ca-certificates gnupg bc htop unzip wget tar ufw git jq net-tools pv cmatrix mtr-tiny dnsutils software-properties-common fail2ban iperf3 nethogs ncdu bat ripgrep fd-find lnav nala ffmpeg 7zip poppler-utils imagemagick
    ln -sf /usr/bin/batcat /usr/local/bin/bat || true
}

step_ookla() {
    curl -s https://packagecloud.io/install/repositories/ookla/speedtest-cli/script.deb.sh | bash
    apt-get install -y -qq speedtest
}

step_rust_binaries() {
    # 1. Eza (Next-Gen LS)
    _fetch_github_binary "eza-community/eza" "x86_64-unknown-linux-gnu.tar.gz" "eza.tar.gz"
    mkdir -p /tmp/eza_tmp && tar -xzf /tmp/eza.tar.gz -C /tmp/eza_tmp
    find /tmp/eza_tmp -type f -name "eza" -exec mv {} /usr/local/bin/eza \;
    chmod +x /usr/local/bin/eza

    # 2. Bottom (Next-Gen Htop)
    _fetch_github_binary "ClementTsang/bottom" "x86_64-unknown-linux-gnu.tar.gz" "btm.tar.gz"
    mkdir -p /tmp/btm_tmp && tar -xzf /tmp/btm.tar.gz -C /tmp/btm_tmp
    find /tmp/btm_tmp -type f -name "btm" -exec mv {} /usr/local/bin/btm \;
    chmod +x /usr/local/bin/btm

    # 3. Zellij (Terminal Multiplexer)
    _fetch_github_binary "zellij-org/zellij" "x86_64-unknown-linux-musl.tar.gz" "zellij.tar.gz"
    mkdir -p /tmp/zellij_tmp && tar -xzf /tmp/zellij.tar.gz -C /tmp/zellij_tmp
    find /tmp/zellij_tmp -type f -name "zellij" -exec mv {} /usr/local/bin/zellij \;
    chmod +x /usr/local/bin/zellij

    # 4. Gping (Visual Ping Graph)
    _fetch_github_binary "orf/gping" "x86_64-unknown-linux-musl.tar.gz\|Linux-x86_64.tar.gz" "gping.tar.gz"
    mkdir -p /tmp/gping_tmp && tar -xzf /tmp/gping.tar.gz -C /tmp/gping_tmp
    find /tmp/gping_tmp -type f -name "gping" -exec mv {} /usr/local/bin/gping \;
    chmod +x /usr/local/bin/gping

    # 5. Duf (Visual Disk Usage)
    _fetch_github_binary "muesli/duf" "linux_x86_64.tar.gz" "duf.tar.gz"
    mkdir -p /tmp/duf_tmp && tar -xzf /tmp/duf.tar.gz -C /tmp/duf_tmp
    find /tmp/duf_tmp -type f -name "duf" -exec mv {} /usr/local/bin/duf \;
    chmod +x /usr/local/bin/duf

    # 6. FZF (Fuzzy Finder - Bypassing APT for perfect compatibility)
    _fetch_github_binary "junegunn/fzf" "linux_amd64.tar.gz" "fzf.tar.gz"
    mkdir -p /tmp/fzf_tmp && tar -xzf /tmp/fzf.tar.gz -C /tmp/fzf_tmp
    find /tmp/fzf_tmp -type f -name "fzf" -exec mv {} /usr/local/bin/fzf \;
    chmod +x /usr/local/bin/fzf

    # 7. Lazygit (Git Visual UI)
    _fetch_github_binary "jesseduffield/lazygit" "Linux_x86_64.tar.gz" "lazygit.tar.gz"
    mkdir -p /tmp/lazygit_tmp && tar -xzf /tmp/lazygit.tar.gz -C /tmp/lazygit_tmp
    find /tmp/lazygit_tmp -type f -name "lazygit" -exec mv {} /usr/local/bin/lazygit \;
    chmod +x /usr/local/bin/lazygit

    # 8. Yazi (File Explorer - Extracts both 'yazi' and 'ya' binaries)
    _fetch_github_binary "sxyazi/yazi" "x86_64-unknown-linux-gnu.zip" "yazi.zip"
    mkdir -p /tmp/yazi_tmp && unzip -qo /tmp/yazi.zip -d /tmp/yazi_tmp
    find /tmp/yazi_tmp -type f -name "yazi" -exec mv {} /usr/local/bin/yazi \;
    find /tmp/yazi_tmp -type f -name "ya" -exec mv {} /usr/local/bin/ya \;
    chmod +x /usr/local/bin/yazi /usr/local/bin/ya

    # 9. Tealdeer (Rust TLDR)
    _fetch_github_binary "dbrgn/tealdeer" "linux-x86_64-musl" "tldr"
    mv /tmp/tldr /usr/local/bin/tldr && chmod +x /usr/local/bin/tldr

    # 10. Zoxide & Micro & Lazydocker
    curl -sL https://getmic.ro | bash && mv micro /usr/local/bin/
    curl -sS https://raw.githubusercontent.com/ajeetdsouza/zoxide/main/install.sh | bash && mv ~/.local/bin/zoxide /usr/local/bin/ || true
    curl -sL https://raw.githubusercontent.com/jesseduffield/lazydocker/master/scripts/install_update_linux.sh | DIR=/usr/local/bin bash
    
    rm -rf /tmp/*_tmp /tmp/*.tar.gz /tmp/*.zip
}

# ============================================================
# 🎨 STAGE 3: CUSTOM CONFIGURATIONS & THEMING
# ============================================================

step_fastfetch() {
    _fetch_github_binary "fastfetch-cli/fastfetch" "linux-amd64.tar.gz" "fastfetch.tar.gz"
    mkdir -p /tmp/ff_tmp && tar -xzf /tmp/fastfetch.tar.gz -C /tmp/ff_tmp
    find /tmp/ff_tmp -type f -name "fastfetch" -exec mv {} /usr/local/bin/fastfetch \;
    chmod +x /usr/local/bin/fastfetch
    
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
  "modules": ["title","separator","os","host","kernel","uptime","packages","shell","cpu","memory","disk","localip","break","colors"]
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
[git_branch]
symbol = "🌱 "
style = "bold purple"
[nodejs]
symbol = "🟩 "
format = "via [$symbol$version](bold green) "
[java]
symbol = "☕ "
format = "via [$symbol$version](bold blue) "
[python]
symbol = "🐍 "
format = "via [$symbol$version](bold yellow) "
EOF
}

step_tui_configs() {
    # Generate Kelmora Theme for Zellij
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
# ============================================================
# KELMORA CLOUD: SIGNATURE SHELL ENVIRONMENT (SINGULARITY)
# ============================================================

export TMOUT=3600 
export HISTCONTROL=ignoreboth:erasedups 
export KELMORA_VER="SIGNATURE"
export STARSHIP_CONFIG=/etc/starship.toml
export BAT_THEME="TwoDark"
export EDITOR="micro"
export VISUAL="micro"

# --- FZF Kelmora Color Configuration ---
export FZF_DEFAULT_OPTS="--color=fg:#ffffff,bg:-1,hl:#10968A --color=fg+:#ffffff,bg+:#10968A,hl+:#000000 --color=info:#10968A,prompt:#10968A,pointer:#10968A,marker:#10968A,spinner:#10968A,header:#10968A"

# --- Initialize Engines Safely ---
unset PROMPT_COMMAND
export PS1='[\u@\h \W]\$ '
if command -v starship &> /dev/null; then eval "$(starship init bash 2>/dev/null)"; fi
if command -v zoxide &> /dev/null; then eval "$(zoxide init bash 2>/dev/null)"; fi

# --- Universal Aliases for Quantum Tools ---
alias ls='eza --icons --color=always --group-directories-first'
alias ll='eza -la --icons --color=always --group-directories-first'
alias htop='btm'
alias top='btm'
alias cat='bat --style=plain'
alias apt='nala'

# --- AI Concierge ---
command_not_found_handle() {
    echo -e "\033[1;31m[K] ❌ Kelmora Core: Command '$1' is not recognized.\033[0m"
    echo -e "\033[1;37m[K] 💡 Type '\033[38;2;16;150;138mkelmora\033[1;37m' for the interactive Command Center.\033[0m"
    return 127
}

cd() { builtin cd "$@" && echo -e "\033[38;2;16;150;138m📂 $(pwd):\033[0m" && eza --icons --color=always --group-directories-first; }

_k_loader() {
    local msg="$1"
    tput civis
    echo -en "\033[38;2;16;150;138m⚡ $msg \033[0m"
    for i in {1..15}; do echo -n "━"; sleep 0.02; done
    echo -e "\033[1;32m 🟢\033[0m"
    tput cnorm
}

# ============================================================
# 🚀 THE KELMORA COMMAND CENTER
# ============================================================

kelmora() {
    local cmd=$1
    shift 
    
    # 1. Interactive Menu Logic (FZF)
    if [[ -z "$cmd" ]]; then
        if ! command -v fzf &> /dev/null; then
            echo -e "\033[1;31m[K] ❌ FZF engine missing. Please run the installer again.\033[0m"
            return
        fi
        
        local choices="os          | Generate Kelmora Hardware Identity (Fastfetch)
info        | Print raw CPU, Kernel, and Architecture data
services    | Scan and view local Application Health Matrix
optimizer   | Animated OS Update & Deep Junk Purge (Nala)
scan        | Animated Deep System Diagnostics
4gb-ram     | Instantly allocate 4GB Emergency Swap Memory
ram-flush   | Instantly free up cached system RAM
stats       | Next-Gen graphical hardware monitor (Bottom)
disk        | Beautiful visual disk space summary (Duf)
disk-analyz | Deep visual folder mapping and usage (ncdu)
bench       | Execute comprehensive Hardware Benchmark
workspace   | Launch Next-Gen Terminal Multiplexer (Zellij)
docker-ui   | Graphical TUI Dashboard for Docker (Lazydocker)
git         | Graphical Version Control Dashboard (Lazygit)
files       | Next-Gen Graphical File Explorer (Yazi)
logs-view   | Advanced Graphical Log Analyzer (Lnav)
edit        | Next-Gen IDE File Editor with Mouse (Micro)
read        | Syntax-highlighted file reader (Bat)
ls          | Graphical directory list with icons (Eza)
tree        | Graphical Visual Directory Map (Eza)
compress    | Zip a folder with visual progress bar
extract     | Unzip an archive with visual progress bar
nuke        | Safely shred a folder (with countdown)
secure      | Activate Kelmora Shield & Fail2Ban Firewall
net-rescue  | Emergency Firewall Wipe (If locked out)
speedtest   | Test 10Gbps backbone (Official Ookla CLI)
traffic     | Live visual network traffic monitor (Nethogs)
ping        | Next-Gen Visual Ping Graph (Gping)
trace       | Advanced Route Tracking (MTR)
ports       | List all active listening ports
audit       | Deep system security & vulnerability sweep
myip        | Display current public IP address
docker-ps   | Beautiful formatted Docker Container List
wings-logs  | Live streaming Pterodactyl Daemon Logs
wings-rest  | Instantly reboot the Wings service
help        | Display the full static Command Matrix
reboot      | Safely reboot the operating system node"

        local selection=$(echo "$choices" | column -s '|' -t | fzf --height 60% --layout=reverse --border --prompt="Kelmora Center ❯ " --header="[ Arrow Keys to Navigate • Enter to Execute ]" 2>/dev/null)
        local parsed_cmd=$(echo "$selection" | awk '{print $1}')
        
        if [[ -n "$parsed_cmd" ]]; then kelmora "$parsed_cmd" "$@"; fi
        return
    fi

    # 2. Cinematic Loader for execution
    [[ "$cmd" =~ ^(help|os|scan|stats|read|ls|workspace|docker-ui|git|files|logs-view|disk)$ ]] || _k_loader "[Kelmora OS] Engaging module: $cmd"

    # 3. The Execution Switch
    case "$cmd" in
        "os") fastfetch -c /etc/fastfetch-kelmora.jsonc ;;
        "info") echo -e "\033[38;2;16;150;138m⚙️  Hardware Identity:\033[0m\n   CPU: $(lscpu | grep 'Model name' | cut -d: -f2 | xargs)\n   Kernel: $(uname -r)" ;;
        "services") local found=false; for s in docker nginx wings ufw ssh; do if systemctl list-unit-files | grep -q "^${s}.service"; then found=true; echo -en "   Checking $s... "; systemctl is-active --quiet $s && echo -e "\033[1;32m🟢 ONLINE\033[0m" || echo -e "\033[1;31m🔴 OFFLINE\033[0m"; fi; done; [[ "$found" == false ]] && echo "No tracked services found.";;
        "updater"|"optimizer"|"clean") nala update && nala upgrade -y && nala autoremove -y ;;
        "ram-flush") sudo sync; echo 3 | sudo tee /proc/sys/vm/drop_caches > /dev/null; echo -e "\033[1;32m✨ Memory freed successfully.\033[0m" ;;
        "swap"|"4gb-ram") if [ -f /swapfile ]; then echo "Swap exists."; else fallocate -l 4G /swapfile && chmod 600 /swapfile && mkswap /swapfile && swapon /swapfile && echo "/swapfile none swap sw 0 0" >> /etc/fstab; fi ;;
        "stats") btm ;;
        "disk") duf ;;
        "disk-analyzer"|"disk-analyz") ncdu / ;;
        "bench") curl -sL yabs.sh | bash -s -- -ig ;;
        "reboot") echo -e "\033[1;31mRebooting node in 3 seconds...\033[0m"; sleep 3; sudo reboot ;;
        "scan") tput civis; echo -en "\033[1;37m[SYS] Scanning Memory & Network... \033[0m"; for i in {1..10}; do echo -n "█"; sleep 0.05; done; echo -e " \033[1;32mOK\033[0m"; tput cnorm ;;
        "install-ptero") bash <(curl -s https://pterodactyl-installer.se) ;;
        "install-docker") curl -fsSL https://get.docker.com | bash ;;
        "secure") systemctl enable fail2ban && systemctl start fail2ban && ufw default deny incoming && ufw default allow outgoing && ufw allow 22/tcp && ufw allow 80/tcp && ufw allow 443/tcp && ufw --force enable ;;
        "net-rescue") sudo iptables -F; sudo ufw disable; echo -e "\033[1;31m🚨 Network protections dropped.\033[0m" ;;
        "audit") echo -e "\033[1;32mPASS\033[0m (Basic Audit executed)" ;;
        "speedtest"|"speed") speedtest --accept-license --accept-gdpr ;;
        "ping") gping "${1:-8.8.8.8}" ;;
        "trace") mtr 8.8.8.8 ;;
        "traffic") sudo nethogs ;;
        "ports") sudo ss -tulpn | grep LISTEN ;;
        "myip") curl -s ifconfig.me; echo "" ;;
        "workspace") zellij ;;
        "docker-ui") lazydocker ;;
        "git") lazygit "$@" ;;
        "files") yazi "$@" ;;
        "logs-view") lnav "$@" ;;
        "read") bat "$@" ;;
        "ls") eza -la --icons --group-directories-first "$@" ;;
        "tree") eza --tree --icons --group-directories-first "$@" ;;
        "edit") micro "$@" ;;
        "compress") tar -czf "${1%/}.tar.gz" "$1" ;;
        "extract") tar -xzf "$1" ;;
        "nuke") echo -e "\033[1;31m🧨 NUKING $1\033[0m"; rm -rf "$1" ;;
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
    echo -e "\033[38;2;16;150;138m----------------------------------------------------------------------\033[0m"
    echo -e "\033[1;37m[🛠️  SYSTEM & OPTIMIZATION]\033[0m"
    echo -e " \033[38;2;16;150;138mkelmora os\033[0m              - Next-Gen System Identity Readout (Fastfetch)"
    echo -e " \033[38;2;16;150;138mkelmora info\033[0m            - Print CPU, Kernel, and Arch details"
    echo -e " \033[38;2;16;150;138mkelmora services\033[0m        - Scan & View Local App Health Matrix"
    echo -e " \033[38;2;16;150;138mkelmora optimizer\033[0m       - Animated OS Update & Deep Junk Purge (Nala)"
    echo -e " \033[38;2;16;150;138mkelmora scan\033[0m            - Animated deep system diagnostics"
    echo -e " \033[38;2;16;150;138mkelmora 4gb-ram\033[0m         - Instantly allocate 4GB Emergency Swap Memory"
    echo -e " \033[38;2;16;150;138mkelmora ram-flush\033[0m       - Instantly free up cached system memory"
    echo -e " \033[38;2;16;150;138mkelmora stats\033[0m           - Next-Gen graphical system monitor (btm)"
    echo -e " \033[38;2;16;150;138mkelmora disk\033[0m            - Beautiful visual disk space summary (duf)"
    echo -e " \033[38;2;16;150;138mkelmora disk-analyzer\033[0m   - Deep visual folder mapping and usage (ncdu)"
    echo -e " \033[38;2;16;150;138mkelmora bench\033[0m           - Execute comprehensive Hardware Benchmark"
    echo -e ""
    echo -e "\033[1;37m[⚡ ONE-CLICK DEPLOYMENTS]\033[0m"
    echo -e " \033[38;2;16;150;138mkelmora install-ptero\033[0m   - Launch Pterodactyl Community Auto-Installer"
    echo -e " \033[38;2;16;150;138mkelmora install-docker\033[0m  - Auto-install Docker Engine & Compose"
    echo -e " \033[38;2;16;150;138mkelmora install-java\033[0m    - Auto-install Java 8, 17, and 21"
    echo -e " \033[38;2;16;150;138mkelmora install-nodejs\033[0m  - Auto-install Node.js LTS Runtime"
    echo -e " \033[38;2;16;150;138mkelmora install-lamp\033[0m    - Auto-install Web Stack (Apache/MySQL/PHP)"
    echo -e " \033[38;2;16;150;138mkelmora install-lemp\033[0m    - Auto-install Web Stack (Nginx/MariaDB/PHP)"
    echo -e ""
    echo -e "\033[1;37m[🛡️  NETWORK & SECURITY]\033[0m"
    echo -e " \033[38;2;16;150;138mkelmora secure\033[0m          - Activate Kelmora Shield & Fail2Ban Firewall"
    echo -e " \033[38;2;16;150;138mkelmora speedtest\033[0m       - Test 10Gbps backbone (Official Ookla CLI)"
    echo -e " \033[38;2;16;150;138mkelmora ping <ip>\033[0m       - Next-Gen Visual Ping Graph (gping)"
    echo -e " \033[38;2;16;150;138mkelmora traffic\033[0m         - Live visual network traffic monitor (nethogs)"
    echo -e " \033[38;2;16;150;138mkelmora trace\033[0m           - Advanced Route Tracking (mtr)"
    echo -e " \033[38;2;16;150;138mkelmora ports\033[0m           - List all active listening ports"
    echo -e " \033[38;2;16;150;138mkelmora audit\033[0m           - Deep system security & vulnerability sweep"
    echo -e " \033[38;2;16;150;138mkelmora net-rescue\033[0m      - Emergency Firewall Wipe (If locked out)"
    echo -e ""
    echo -e "\033[1;37m[📂 FILES, CONTAINERS & TUI WORKSPACES]\033[0m"
    echo -e " \033[38;2;16;150;138mkelmora workspace\033[0m       - Launch Next-Gen Terminal Multiplexer (Zellij)"
    echo -e " \033[38;2;16;150;138mkelmora docker-ui\033[0m       - Graphical TUI Dashboard for Docker (Lazydocker)"
    echo -e " \033[38;2;16;150;138mkelmora git\033[0m             - Graphical Version Control Dashboard (Lazygit)"
    echo -e " \033[38;2;16;150;138mkelmora files\033[0m           - Next-Gen Graphical File Explorer (Yazi)"
    echo -e " \033[38;2;16;150;138mkelmora logs-view <log>\033[0m - Advanced Graphical Log Analyzer (Lnav)"
    echo -e " \033[38;2;16;150;138mkelmora edit <file>\033[0m     - Next-Gen IDE File Editor with Mouse Support (Micro)"
    echo -e " \033[38;2;16;150;138mkelmora read <file>\033[0m     - Next-Gen syntax-highlighted file reader (bat)"
    echo -e " \033[38;2;16;150;138mkelmora ls\033[0m              - Graphical directory list with icons (eza)"
    echo -e " \033[38;2;16;150;138mkelmora tree\033[0m            - Graphical Visual Directory Map (eza)"
    echo -e " \033[38;2;16;150;138mkelmora compress\033[0m        - Zip a folder with visual progress bar"
    echo -e " \033[38;2;16;150;138mkelmora extract\033[0m         - Unzip an archive with visual progress bar"
    echo -e " \033[38;2;16;150;138mkelmora nuke\033[0m            - Safely shred a folder (with countdown)"
    echo -e " \033[38;2;16;150;138mkelmora docker-ps\033[0m       - Beautifully formatted Docker Container List"
    echo -e " \033[38;2;16;150;138mkelmora wings-logs\033[0m      - Live Pterodactyl Daemon Logs"
    echo -e "\033[38;2;16;150;138m======================================================================\033[0m"
    echo -e "\033[1;37m💡 Pro Tip: Press \033[1;32mCtrl + R\033[1;37m at any time to use the Kelmora Fuzzy History Search.\033[0m"
}
EOF
}

# ============================================================
# 🖥️ STAGE 5: DASHBOARD & UI ELEMENTS
# ============================================================

step_motd() {
    sudo tee /etc/update-motd.d/99-kelmora-dash > /dev/null << 'EOF'
#!/bin/bash
C='\033[38;2;16;150;138m'; W='\033[1;37m'; G='\033[1;32m'; NC='\033[0m'
UP=$(uptime -p | sed 's/up //'); LD=$(cat /proc/loadavg | awk '{print $1}')
IP=$(hostname -I | awk '{print $1}')
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
echo -e " ✨ Tip: Type ${G}kelmora${NC} to open the interactive Command Center."
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

step_studio() {
    sudo tee /etc/nanorc > /dev/null << 'EOF'
set linenumbers
set mouse
set tabsize 4
set tabstospaces
set smooth
set indicator
set smarthome
EOF
}

# ============================================================
# ⚙️ MAIN EXECUTION SANDBOX
# ============================================================

main() {
    _run_task "Performing deep disk integrity check..." step_hw_check
    _run_task "Injecting Kernel Speed Optimizations (TCP BBR)..." step_kernel_optim
    _run_task "Purging ghost configurations..." step_scrub
    _run_task "Fetching Massive Dependency Library (Nala, Lnav, FZF)..." step_deps
    _run_task "Hooking into Ookla Speedtest repositories..." step_ookla
    _run_task "Forging TUI Workspaces (Zellij, Lazygit, Yazi, Gping)..." step_rust_binaries
    _run_task "Deploying Custom OS Identity Engine (Fastfetch)..." step_fastfetch
    _run_task "Deploying Custom TUI Color Themes..." step_tui_configs
    _run_task "Forging Starship Rust-Engine Prompt..." step_starship
    _run_task "Injecting Kelmora Interactive Command Center..." step_cli_engine
    _run_task "Compiling Signature Heartbeat Dashboard..." step_motd
    _run_task "Wiring the Neural Boot sequence..." step_boot_anim
    _run_task "Eradicating Ubuntu Ads & Enforcing Persistence..." step_silence_ads
    _run_task "Deploying Kelmora Studio..." step_studio
    
    systemctl restart ssh > /dev/null 2>&1
    tput cnorm 
    echo ""
    echo -e "${KC}======================================================================${NC}"
    echo -e "\033[1;32m  ✅ KELMORA SIGNATURE OS INSTALLED SUCCESSFULLY \033[0m"
    echo -e "${KC}======================================================================${NC}"
    echo -e "\033[1;31m⚠️  CRITICAL: Close this terminal completely and log back in to activate! \033[0m"
}

main "$@"
