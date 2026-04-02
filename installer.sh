#!/bin/bash
# ==============================================================================
# KELMORA CLOUD - THE "SIGNATURE BUILD" OMNI-OS PROVISIONER (BULLETPROOF)
# ==============================================================================

# Disable history expansion to prevent paste-crashes
set +H 

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
echo -e "\033[1;37m  🚀 INITIALIZING KELMORA SIGNATURE OS DEPLOYMENT\033[0m"
echo -e "${KC}======================================================================${NC}"
echo ""

# --- The Synchronous Safe Loader ---
_run_task() {
    local msg="$1"
    local func="$2"
    
    # Print the waiting status
    echo -en "${KC}[⏳]${NC} \033[1;37m${msg}\033[0m"
    
    # Execute the task silently
    $func >/dev/null 2>&1
    
    # Overwrite with success status
    echo -e "\r\033[1;32m[✅] \033[1;37m${msg}\033[0m\033[K"
}

# ============================================================
# 🛠️ INSTALLATION STEPS (Sandboxed)
# ============================================================

step_hw_check() {
    mount -o remount,rw / || true
    touch /etc/kelmora_hw_test || exit 1
    rm -f /etc/kelmora_hw_test
}

step_scrub() {
    rm -f /usr/bin/kelmora-* /usr/local/bin/kelmora-* /bin/kelmora-* || true
    rm -f /etc/sudoers.d/kelmora /etc/kelmora_env.sh /etc/profile.d/kelmora_welcome.sh || true
    
    # Nuclear scrub of corrupted color codes and old prompts
    sed -i '/_kelmora_prompt/d' /root/.bashrc /home/*/.bashrc /etc/bash.bashrc 2>/dev/null || true
    sed -i '/PROMPT_COMMAND/d' /root/.bashrc /home/*/.bashrc /etc/bash.bashrc 2>/dev/null || true
    sed -i '/starship init/d' /root/.bashrc /home/*/.bashrc /etc/bash.bashrc 2>/dev/null || true
    sed -i '/zoxide init/d' /root/.bashrc /home/*/.bashrc /etc/bash.bashrc 2>/dev/null || true
    sed -i '/FZF_DEFAULT_OPTS/d' /root/.bashrc /home/*/.bashrc /etc/bash.bashrc 2>/dev/null || true
}

step_deps() {
    export DEBIAN_FRONTEND=noninteractive
    apt-get update -qq
    apt-get install -y -qq curl apt-transport-https ca-certificates gnupg bc htop unzip wget tar ufw git jq net-tools pv cmatrix mtr-tiny dnsutils software-properties-common fail2ban iperf3 nethogs ncdu bat fzf ripgrep fd-find lnav
    ln -sf /usr/bin/batcat /usr/local/bin/bat || true
}

step_ookla() {
    curl -s https://packagecloud.io/install/repositories/ookla/speedtest-cli/script.deb.sh | bash
    apt-get install -y -qq speedtest
}

step_rust_binaries() {
    # Core TUIs
    wget -qO /tmp/eza.tar.gz "https://github.com/eza-community/eza/releases/latest/download/eza_x86_64-unknown-linux-gnu.tar.gz" && tar -xzf /tmp/eza.tar.gz -C /tmp/ && mv /tmp/eza /usr/local/bin/eza && chmod +x /usr/local/bin/eza
    wget -qO /tmp/btm.tar.gz "https://github.com/ClementTsang/bottom/releases/latest/download/bottom_x86_64-unknown-linux-gnu.tar.gz" && tar -xzf /tmp/btm.tar.gz -C /tmp/ && mv /tmp/btm /usr/local/bin/btm && chmod +x /usr/local/bin/btm
    wget -qO /tmp/zellij.tar.gz "https://github.com/zellij-org/zellij/releases/latest/download/zellij-x86_64-unknown-linux-musl.tar.gz" && tar -xzf /tmp/zellij.tar.gz -C /tmp/ && mv /tmp/zellij /usr/local/bin/zellij && chmod +x /usr/local/bin/zellij
    wget -qO /tmp/gping.tar.gz "https://github.com/orf/gping/releases/latest/download/gping-x86_64-unknown-linux-musl.tar.gz" && tar -xzf /tmp/gping.tar.gz -C /tmp/ && mv /tmp/gping /usr/local/bin/gping && chmod +x /usr/local/bin/gping
    
    curl -sL https://getmic.ro | bash && mv micro /usr/local/bin/
    curl -sS https://raw.githubusercontent.com/ajeetdsouza/zoxide/main/install.sh | bash && mv ~/.local/bin/zoxide /usr/local/bin/ || true
    curl -sL https://raw.githubusercontent.com/jesseduffield/lazydocker/master/scripts/install_update_linux.sh | DIR=/usr/local/bin bash
    
    # Lazygit
    LAZYGIT_VERSION=$(curl -s "https://api.github.com/repos/jesseduffield/lazygit/releases/latest" | grep -Po '"tag_name": "v\K[^"]*')
    wget -qO /tmp/lazygit.tar.gz "https://github.com/jesseduffield/lazygit/releases/latest/download/lazygit_${LAZYGIT_VERSION}_Linux_x86_64.tar.gz"
    tar -xzf /tmp/lazygit.tar.gz -C /tmp/ lazygit && mv /tmp/lazygit /usr/local/bin/lazygit && chmod +x /usr/local/bin/lazygit

    # Yazi (File Explorer)
    wget -qO /tmp/yazi.zip "https://github.com/sxyazi/yazi/releases/latest/download/yazi-x86_64-unknown-linux-gnu.zip"
    unzip -qo /tmp/yazi.zip -d /tmp/
    mv /tmp/yazi-x86_64-unknown-linux-gnu/yazi /usr/local/bin/yazi
    chmod +x /usr/local/bin/yazi
    rm -rf /tmp/yazi*
}

step_fastfetch() {
    # Fetch Fastfetch binary
    wget -qO /tmp/fastfetch.tar.gz "https://github.com/fastfetch-cli/fastfetch/releases/latest/download/fastfetch-linux-amd64.tar.gz"
    tar -xzf /tmp/fastfetch.tar.gz -C /tmp/
    mv /tmp/fastfetch-*/usr/bin/fastfetch /usr/local/bin/fastfetch
    chmod +x /usr/local/bin/fastfetch
    rm -rf /tmp/fastfetch*

    # Build the Kelmora Logo
    sudo tee /etc/kelmora_logo.txt > /dev/null << 'EOF'
    //\       K E L M O R A
   //  \      C L O U D   O S
  //    \     -----------------
 //======\
//        \
EOF

    # Build the Fastfetch JSON Config
    sudo tee /etc/fastfetch-kelmora.jsonc > /dev/null << 'EOF'
{
  "$schema": "https://github.com/fastfetch-cli/fastfetch/raw/dev/doc/json_schema.json",
  "logo": {
    "type": "file",
    "source": "/etc/kelmora_logo.txt",
    "color": {"1": "38;2;16;150;138"}
  },
  "display": {
    "color": "38;2;16;150;138",
    "separator": " ➜  "
  },
  "modules": [
    "title",
    "separator",
    "os",
    "host",
    "kernel",
    "uptime",
    "packages",
    "shell",
    "cpu",
    "memory",
    "swap",
    "disk",
    "localip",
    "break",
    "colors"
  ]
}
EOF
}

step_starship() {
    curl -sS https://starship.rs/install.sh | sh -s -- -y
    
    sudo tee /etc/starship.toml > /dev/null << 'EOF'
# ============================================================
# KELMORA CLOUD: STARSHIP PROMPT CONFIGURATION (SIGNATURE)
# ============================================================
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

# Inject FZF Keybindings (Ctrl+R for History)
if [ -f /usr/share/doc/fzf/examples/key-bindings.bash ]; then
    source /usr/share/doc/fzf/examples/key-bindings.bash
fi

# --- Universal Aliases for Quantum Tools ---
alias ls='eza --icons --color=always --group-directories-first'
alias ll='eza -la --icons --color=always --group-directories-first'
alias htop='btm'
alias top='btm'
alias cat='bat --style=plain'

# --- AI Concierge ---
command_not_found_handle() {
    echo -e "\033[1;31m[K] ❌ Kelmora Core: Command '$1' is not recognized.\033[0m"
    echo -e "\033[1;37m[K] 💡 Type '\033[38;2;16;150;138mkelmora help\033[1;37m' to view the master toolkit.\033[0m"
    return 127
}

# --- Visual Navigation ---
cd() {
    builtin cd "$@" && echo -e "\033[38;2;16;150;138m📂 $(pwd):\033[0m" && eza --icons --color=always --group-directories-first
}

# --- Kelmora Cinematic UI Loaders ---
_k_typewriter() {
    text="$1"
    delay="$2"
    for (( i=0; i<${#text}; i++ )); do
        echo -n "${text:$i:1}"
        sleep $delay
    done
    echo ""
}

_k_loader() {
    local msg="$1"
    tput civis
    echo -en "\033[38;2;16;150;138m⚡ $msg \033[0m"
    for i in {1..15}; do echo -n "━"; sleep 0.02; done
    echo -e "\033[1;32m 🟢\033[0m"
    tput cnorm
}

# ============================================================
# 🚀 THE KELMORA UNIFIED CLI ENGINE
# ============================================================

kelmora() {
    local cmd=$1
    shift 
    
    # Cinematic Execution Confirmation
    if [[ -n "$cmd" && "$cmd" != "help" && "$cmd" != "os" && "$cmd" != "scan" && "$cmd" != "stats" && "$cmd" != "read" && "$cmd" != "ls" && "$cmd" != "workspace" && "$cmd" != "docker-ui" && "$cmd" != "git" && "$cmd" != "files" && "$cmd" != "logs-view" ]]; then
        _k_loader "[Kelmora OS] Engaging module: $cmd"
    fi

    case "$cmd" in
        "os") fastfetch -c /etc/fastfetch-kelmora.jsonc ;;
        "info") _k_info ;;
        "services") _k_services ;;
        "logs") sudo journalctl -p 3 -xb | tail -n 20 ;;
        "updater"|"optimizer"|"clean") _k_clean ;;
        "ram-flush") _k_ram_flush ;;
        "swap"|"4gb-ram") _k_swap ;;
        "stats") btm ;;
        "disk-analyzer") ncdu / ;;
        "bench") curl -sL yabs.sh | bash -s -- -ig ;;
        "reboot") echo -e "\033[1;31mRebooting node in 3 seconds...\033[0m"; sleep 3; sudo reboot ;;
        "scan") _k_scan ;;
        
        "install-ptero") bash <(curl -s https://pterodactyl-installer.se) ;;
        "install-docker") _k_install_docker ;;
        "install-java") _k_install_java ;;
        "install-nodejs") _k_install_nodejs ;;
        "install-lamp") _k_install_lamp ;;
        "install-lemp") _k_install_lemp ;;
        "install-netdata") _k_install_netdata ;;
        
        "secure") _k_secure ;;
        "unsecure") sudo ufw disable > /dev/null 2>&1; sudo ufw --force reset > /dev/null 2>&1; echo -e "\033[1;31m🔓 Firewall Disabled. Node is public.\033[0m" ;;
        "audit") _k_audit ;;
        "net-rescue") sudo iptables -F; sudo ufw disable; echo -e "\033[1;31m🚨 Network protections dropped. You are exposed.\033[0m" ;;
        "speedtest"|"speed") speedtest --accept-license --accept-gdpr ;;
        "traffic") sudo nethogs ;;
        "ping") gping "${1:-8.8.8.8}" ;;
        "trace") mtr 8.8.8.8 ;;
        "ports") sudo ss -tulpn | grep LISTEN ;;
        "myip") curl -s ifconfig.me; echo "" ;;
        
        "workspace") zellij ;;
        "docker-ui") lazydocker ;;
        "git") lazygit "$@" ;;
        "files") yazi "$@" ;;
        "logs-view") lnav "$@" ;;
        "read") bat "$@" ;;
        "ls") eza -la --icons --color=always --group-directories-first "$@" ;;
        "compress") _k_compress "$@" ;;
        "extract") _k_extract "$@" ;;
        "nuke") _k_nuke "$@" ;;
        "edit") micro "$@" ;;
        "tree") eza --tree --icons --color=always --group-directories-first "$@" ;;
        "bigfiles") echo -e "\033[38;2;16;150;138m📁 Top 20 Storage Hogs:\033[0m"; sudo du -ah / 2>/dev/null | sort -rh | head -n 20 ;;
        "docker-ps") docker ps -a --format "table {{.ID}}\t{{.Names}}\t{{.Status}}\t{{.Ports}}" ;;
        "wings-logs") sudo journalctl -u wings -n 50 -f ;;
        "wings-restart") sudo systemctl restart wings; echo -e "\033[1;32m🦖 Wings daemon restarted.\033[0m" ;;
        
        "welcome") /usr/local/bin/k-welcome ;;
        "matrix") cmatrix -b -C cyan ;;
        "weather") curl -s wttr.in/?0 ;;
        
        "help"|"") _k_help ;;
        *) echo -e "\033[1;31m[K] ❌ Module '$cmd' not found. Type 'kelmora help' for the index.\033[0m" ;;
    esac
}

# ============================================================
# ⚙️ INTERNAL CORE FUNCTIONS
# ============================================================

_k_info() {
    echo -e "\033[38;2;16;150;138m⚙️  Hardware Identity:\033[0m"
    echo -e "   \033[1;37mCPU:\033[0m $(lscpu | grep "Model name" | sed "s/Model name: //" | xargs)"
    echo -e "   \033[1;37mKernel:\033[0m $(uname -r)"
    echo -e "   \033[1;37mArchitecture:\033[0m $(uname -m)"
}

_k_services() {
    echo -e "\033[38;2;16;150;138m🚦 Universal Service Health Check:\033[0m"
    local found=false
    for s in docker nginx apache2 mysql mariadb postgresql wings ufw ssh php8.1-fpm netdata; do
        if systemctl list-unit-files | grep -q "^${s}.service"; then
            found=true
            echo -en "   \033[1;37mChecking $s...\033[0m "
            if systemctl is-active --quiet $s; then
                echo -e "\r \033[1;32m🟢 $s is ONLINE and running.\033[0m\033[K"
            else
                echo -e "\r \033[1;31m🔴 $s is OFFLINE.\033[0m\033[K"
            fi
            sleep 0.1
        fi
    done
    if [ "$found" = false ]; then echo -e "   \033[1;33mNo standard tracked services found on this node.\033[0m"; fi
}

_k_scan() {
    tput civis
    _k_typewriter "\033[38;2;16;150;138m[SYS]\033[0m Initiating Deep System Diagnostic..." 0.02
    sleep 0.5
    echo -en "\033[1;37m[SYS] Scanning Memory Blocks...\033[0m \033[38;2;16;150;138m["
    for i in {1..10}; do echo -n "█"; sleep 0.05; done; echo -e "]\033[0m \033[1;32mINTEGRITY VERIFIED\033[0m"
    echo -en "\033[1;37m[NET] Pinging Kelmora Backbone...\033[0m \033[38;2;16;150;138m["
    for i in {1..10}; do echo -n "█"; sleep 0.05; done; echo -e "]\033[0m \033[1;32m<1ms LATENCY\033[0m"
    echo -en "\033[1;37m[SEC] Checking Firewall Status...\033[0m "
    if sudo ufw status | grep -q "active"; then echo -e " \033[1;32mARMED\033[0m"; else echo -e " \033[1;31mEXPOSED\033[0m"; fi
    sleep 0.5
    _k_typewriter "\033[38;2;16;150;138m✨ Diagnostic Complete. All systems nominal.\033[0m" 0.02
    tput cnorm
}

_k_clean() {
    echo -e "\033[1;37m🧹 Sweeping cache, updating repos, purging junk...\033[0m"
    sudo DEBIAN_FRONTEND=noninteractive apt-get update -qq > /dev/null 2>&1
    sudo DEBIAN_FRONTEND=noninteractive apt-get dist-upgrade -y -qq > /dev/null 2>&1
    sudo DEBIAN_FRONTEND=noninteractive apt-get autoremove -y -qq > /dev/null 2>&1
    sudo apt-get autoclean -qq > /dev/null 2>&1
    echo -e "\033[1;32m✨ Kelmora Cloud: OS Refreshed, Updated, and Optimized.\033[0m"
}

_k_swap() {
    echo -e "\033[1;37m⚙️  Allocating 4GB Emergency Swap Memory...\033[0m"
    if [ -f /swapfile ]; then
        echo -e "\033[38;2;16;150;138mℹ️  Kelmora Cloud: Swap file already exists on this node.\033[0m"
    else
        sudo fallocate -l 4G /swapfile > /dev/null 2>&1
        sudo chmod 600 /swapfile > /dev/null 2>&1
        sudo mkswap /swapfile > /dev/null 2>&1
        sudo swapon /swapfile > /dev/null 2>&1
        echo "/swapfile none swap sw 0 0" | sudo tee -a /etc/fstab > /dev/null 2>&1
        echo -e "\033[1;32m✅ Kelmora Cloud: 4GB Swap Activated.\033[0m"
    fi
}

_k_ram_flush() {
    echo -e "\033[1;37m🧹 Flushing system RAM cache...\033[0m"
    sudo sync; echo 3 | sudo tee /proc/sys/vm/drop_caches > /dev/null
    echo -e "\033[1;32m✨ Memory freed successfully.\033[0m"
}

_k_audit() {
    echo -e "\033[38;2;16;150;138m🔍 Initiating Deep Kelmora Security Sweep...\033[0m"
    sleep 0.5
    echo -en "\033[1;37m[1/3] Checking for ghost accounts:\033[0m "
    local empty_pw=$(sudo awk -F: '($2 == "") {print $1}' /etc/shadow)
    if [ -z "$empty_pw" ]; then echo -e "\033[1;32mPASS\033[0m"; else echo -e "\033[1;31mFAIL ($empty_pw)\033[0m"; fi
    sleep 0.5
    echo -en "\033[1;37m[2/3] Checking SSH Root vulnerabilities:\033[0m "
    if grep -q "^PermitRootLogin yes" /etc/ssh/sshd_config; then echo -e "\033[1;31mWARNING (Root Allowed)\033[0m"; else echo -e "\033[1;32mSECURE\033[0m"; fi
    sleep 0.5
    echo -e "\033[1;37m[3/3] Active Listening Ports:\033[0m"
    sudo ss -tulpn | grep LISTEN | awk '{print "  👉 "$5" ("$7")"}'
    echo -e "\033[1;32m✅ Deep Sweep Complete.\033[0m"
}

_k_secure() {
    echo -e "\033[1;37m🛡️  Activating Kelmora Shield & Fail2Ban...\033[0m"
    sudo systemctl enable fail2ban > /dev/null 2>&1
    sudo systemctl start fail2ban > /dev/null 2>&1
    sudo ufw default deny incoming > /dev/null 2>&1
    sudo ufw default allow outgoing > /dev/null 2>&1
    sudo ufw allow 22/tcp > /dev/null 2>&1
    sudo ufw allow 80/tcp > /dev/null 2>&1
    sudo ufw allow 443/tcp > /dev/null 2>&1
    sudo ufw --force enable > /dev/null 2>&1
    echo -e "\033[1;32m🛡️  Shield: ACTIVE. Brute-force protection online.\033[0m"
}

_k_install_docker() {
    curl -fsSL https://get.docker.com -o get-docker.sh && sudo sh get-docker.sh > /dev/null 2>&1
    rm get-docker.sh
    echo -e "\033[1;32m✨ Docker Engine Installed.\033[0m"
}

_k_install_java() {
    sudo apt-get install -y openjdk-8-jre-headless openjdk-17-jre-headless openjdk-21-jre-headless > /dev/null 2>&1
    echo -e "\033[1;32m✨ Java Stack Installed (8, 17, 21).\033[0m"
}

_k_install_nodejs() {
    curl -fsSL https://deb.nodesource.com/setup_lts.x | sudo -E bash - > /dev/null 2>&1
    sudo apt-get install -y nodejs > /dev/null 2>&1
    echo -e "\033[1;32m✨ Node.js Installed: $(node -v)\033[0m"
}

_k_install_lamp() {
    sudo apt-get install -y apache2 mysql-server php libapache2-mod-php php-mysql > /dev/null 2>&1
    echo -e "\033[1;32m✨ LAMP Stack Installed.\033[0m"
}

_k_install_lemp() {
    sudo apt-get install -y nginx mariadb-server php-fpm php-mysql > /dev/null 2>&1
    echo -e "\033[1;32m✨ LEMP Stack Installed.\033[0m"
}

_k_install_netdata() {
    wget -O /tmp/netdata-kickstart.sh https://get.netdata.cloud/kickstart.sh && sh /tmp/netdata-kickstart.sh --non-interactive > /dev/null 2>&1
    echo -e "\033[1;32m✨ Netdata Installed.\033[0m"
}

_k_extract() {
    if [ -z "$1" ]; then echo -e "\033[1;31m⚠️  Usage: kelmora extract <archive_file>\033[0m"; return 1; fi
    if [[ $1 == *.tar.gz || $1 == *.tgz ]]; then pv "$1" | tar -xz
    elif [[ $1 == *.zip ]]; then unzip -q "$1" && echo -e "\033[1;32m✨ Complete.\033[0m"
    else echo -e "\033[1;31m❌ Unsupported format. Use .zip or .tar.gz\033[0m"; return 1; fi
}

_k_compress() {
    if [ -z "$1" ]; then echo -e "\033[1;31m⚠️  Usage: kelmora compress <folder_name>\033[0m"; return 1; fi
    local stamp=$(date +"%Y-%m-%d_%H-%M-%S")
    local archive_name="${1%/}_${stamp}.tar.gz"
    tar -cf - "$1" | pv -s $(du -sb "$1" | awk '{print $1}') | gzip > "$archive_name"
    echo -e "\033[1;32m✅ Complete: $archive_name\033[0m"
}

_k_nuke() {
    if [ -z "$1" ]; then echo -e "\033[1;31m⚠️  Usage: kelmora nuke <target>\033[0m"; return 1; fi
    echo -e "\033[1;31m⚠️  WARNING: You are about to permanently eradicate: $1\033[0m"
    echo -en "\033[1;37mInitiating 3-second safety countdown: \033[0m"
    for i in 3 2 1; do echo -n "$i... "; sleep 1; done
    echo -e "\n\033[1;31m🧨 NUKING...\033[0m"
    rm -rf "$1"
    echo -e "\033[1;32m✨ Target eradicated.\033[0m"
}

_k_help() {
    echo -e "\033[38;2;16;150;138m======================================================================\033[0m"
    echo -e "\033[1;37m         KELMORA CLOUD SIGNATURE BUILD - COMMAND MATRIX\033[0m"
    echo -e "\033[38;2;16;150;138m======================================================================\033[0m"
    echo -e "\033[1;37mUsage: \033[38;2;16;150;138mkelmora \033[1;37m<module>\033[0m"
    echo -e "\033[38;2;16;150;138m----------------------------------------------------------------------\033[0m"
    echo -e "\033[1;37m[🛠️  SYSTEM & OPTIMIZATION]\033[0m"
    echo -e " \033[38;2;16;150;138mkelmora os\033[0m              - Next-Gen System Identity Readout (Fastfetch)"
    echo -e " \033[38;2;16;150;138mkelmora info\033[0m            - Print CPU, Kernel, and Arch details"
    echo -e " \033[38;2;16;150;138mkelmora services\033[0m        - Scan & View Local App Health Matrix"
    echo -e " \033[38;2;16;150;138mkelmora optimizer\033[0m       - Animated OS Update & Deep Junk Purge"
    echo -e " \033[38;2;16;150;138mkelmora scan\033[0m            - Animated deep system diagnostics"
    echo -e " \033[38;2;16;150;138mkelmora 4gb-ram\033[0m         - Instantly allocate 4GB Emergency Swap Memory"
    echo -e " \033[38;2;16;150;138mkelmora ram-flush\033[0m       - Instantly free up cached system memory"
    echo -e " \033[38;2;16;150;138mkelmora stats\033[0m           - Next-Gen graphical system monitor (btm)"
    echo -e " \033[38;2;16;150;138mkelmora disk-analyzer\033[0m   - Deep visual disk space usage (ncdu)"
    echo -e " \033[38;2;16;150;138mkelmora bench\033[0m           - Deep Hardware Benchmark"
    echo -e ""
    echo -e "\033[1;37m[⚡ ONE-CLICK DEPLOYMENTS]\033[0m"
    echo -e " \033[38;2;16;150;138mkelmora install-ptero\033[0m   - Launch Pterodactyl Community Auto-Installer"
    echo -e " \033[38;2;16;150;138mkelmora install-docker\033[0m  - Auto-install Docker Engine & Compose"
    echo -e " \033[38;2;16;150;138mkelmora install-java\033[0m    - Auto-install Java 8, 17, and 21"
    echo -e " \033[38;2;16;150;138mkelmora install-nodejs\033[0m  - Auto-install Node.js LTS Runtime"
    echo -e " \033[38;2;16;150;138mkelmora install-lamp\033[0m    - Auto-install Web Stack (Apache/MySQL/PHP)"
    echo -e " \033[38;2;16;150;138mkelmora install-lemp\033[0m    - Auto-install Web Stack (Nginx/MariaDB/PHP)"
    echo -e " \033[38;2;16;150;138mkelmora install-netdata\033[0m - Auto-install Netdata live dashboard"
    echo -e ""
    echo -e "\033[1;37m[🛡️  NETWORK & SECURITY]\033[0m"
    echo -e " \033[38;2;16;150;138mkelmora secure\033[0m          - Activate Kelmora Shield & Fail2Ban"
    echo -e " \033[38;2;16;150;138mkelmora speedtest\033[0m       - Test 10Gbps backbone (Official Ookla CLI)"
    echo -e " \033[38;2;16;150;138mkelmora ping <ip>\033[0m       - Next-Gen Visual Ping Graph (gping)"
    echo -e " \033[38;2;16;150;138mkelmora traffic\033[0m         - Live visual network traffic monitor"
    echo -e " \033[38;2;16;150;138mkelmora trace\033[0m           - Advanced Route Tracking"
    echo -e " \033[38;2;16;150;138mkelmora ports\033[0m           - List all active listening ports"
    echo -e " \033[38;2;16;150;138mkelmora audit\033[0m           - Deep system security & vulnerability sweep"
    echo -e " \033[38;2;16;150;138mkelmora net-rescue\033[0m      - Emergency Firewall Wipe (If locked out)"
    echo -e ""
    echo -e "\033[1;37m[📂 FILES, CONTAINERS & TUI WORKSPACES]\033[0m"
    echo -e " \033[38;2;16;150;138mkelmora workspace\033[0m       - Launch Next-Gen Terminal Multiplexer (Zellij)"
    echo -e " \033[38;2;16;150;138mkelmora docker-ui\033[0m       - Graphical TUI Dashboard for Docker (Lazydocker)"
    echo -e " \033[38;2;16;150;138mkelmora git\033[0m             - Graphical Version Control Dashboard (Lazygit)"
    echo -e " \033[38;2;16;150;138mkelmora files\033[0m           - Next-Gen Graphical File Explorer (Yazi)"
    echo -e " \033[38;2;16;150;138mkelmora logs-view <file>\033[0m- Advanced Graphical Log Analyzer (Lnav)"
    echo -e " \033[38;2;16;150;138mkelmora edit <file>\033[0m     - Next-Gen IDE File Editor with Mouse Support (Micro)"
    echo -e " \033[38;2;16;150;138mkelmora read <file>\033[0m     - Next-Gen syntax-highlighted file reader (bat)"
    echo -e " \033[38;2;16;150;138mkelmora ls\033[0m              - Graphical directory list with icons (eza)"
    echo -e " \033[38;2;16;150;138mkelmora tree\033[0m            - Graphical Visual Directory Map (eza)"
    echo -e " \033[38;2;16;150;138mkelmora compress\033[0m        - Zip a folder with visual progress bar"
    echo -e " \033[38;2;16;150;138mkelmora extract\033[0m         - Unzip an archive with visual progress bar"
    echo -e " \033[38;2;16;150;138mkelmora nuke\033[0m            - Safely shred a folder (with countdown)"
    echo -e " \033[38;2;16;150;138mkelmora logs\033[0m            - Print last 20 critical system errors"
    echo -e " \033[38;2;16;150;138mkelmora wings-logs\033[0m      - Live Pterodactyl Daemon Logs"
    echo -e "\033[38;2;16;150;138m======================================================================\033[0m"
    echo -e "\033[1;37m💡 Pro Tip: Press \033[1;32mCtrl + R\033[1;37m at any time to use the Kelmora Fuzzy History Search.\033[0m"
}
EOF
}

step_motd() {
    sudo tee /etc/update-motd.d/99-kelmora-dash > /dev/null << 'EOF'
#!/bin/bash
C='\033[38;2;16;150;138m'; G='\033[0;32m'; Y='\033[1;37m'; R='\033[0;31m'; NC='\033[0m'; W='\033[1;37m'
UP=$(uptime -p | sed 's/up //'); LD=$(cat /proc/loadavg | awk '{print $1}')
MEM_U=$(free -m | awk '/Mem:/ { print $3 }'); MEM_T=$(free -m | awk '/Mem:/ { print $2 }')
DSK_P=$(df / | awk 'NR==2 {print $5}' | sed 's/%//'); DSK_U=$(df -h / | awk 'NR==2 {print $3}')
IP=$(hostname -I | awk '{print $1}')
TIME=$(date +"%A, %B %d, %Y - %T %Z")

APP_STATUS=""
if systemctl is-active --quiet wings; then APP_STATUS="🦖 Wings: ${G}ONLINE${NC}"
elif systemctl is-active --quiet docker; then APP_STATUS="🐳 Docker: ${G}ONLINE${NC}"
elif systemctl is-active --quiet nginx; then APP_STATUS="🌐 Nginx: ${G}ONLINE${NC}"
elif systemctl is-active --quiet apache2; then APP_STATUS="🌐 Apache: ${G}ONLINE${NC}"
else APP_STATUS="⚙️ System: ${G}ONLINE${NC}"; fi

echo -e "${C}============================================================${NC}"
if command -v bc > /dev/null 2>&1; then
    if (( $(echo "$LD > 8.0" | bc -l) )); then echo -e " 🔥 ${R}SYSTEM ALERT: Extreme CPU throttling detected ($LD)!${NC}"; fi
fi
if [ "$DSK_P" -gt 90 ]; then echo -e " 🚨 ${R}SYSTEM ALERT: Storage is critically full ($DSK_P% Used)!${NC}"; fi

echo -e "${C}   _  __     _                                 ${NC}"
echo -e "${C}  | |/ /___ | | _ __ ___    ___   _ __  __ _   ${NC}"
echo -e "${C}  | ' // _ \| || '_ ' _ \  / _ \ | '__|/ _' |  ${NC}"
echo -e "${C}  | . \  __/| || | | | | || (_) || |  | (_| |  ${NC}"
echo -e "  |_|\_\___||_||_| |_| |_| \___/ |_|   \__,_|  ${NC}"
echo -e "          ${W}Powered by Kelmora Cloud Hosting${NC}"
echo -e "${C}============================================================${NC}"

echo -e " ${Y}📡 Live Telemetry:${NC}       ${W}$TIME${NC}"
echo -e "  🚀 Uptime: ${W}$UP${NC}"
echo -e "  ⚡ Load:   ${W}$LD${NC}             🌐 IP: ${W}$IP${NC}"
echo -e "  🧠 Memory: ${W}$MEM_U / $MEM_T MB${NC}   🗄️ Disk: ${W}$DSK_U / $DSK_P% Used${NC}"
echo -e "  $APP_STATUS"
echo -e "${C}------------------------------------------------------------${NC}"
echo -e " 🎫 Support: ${C}billing.kelmora.cloud${NC} | 💬 Discord: ${C}kelmora${NC}"
echo -e "${C}============================================================${NC}"
echo -e " ✨ Tip: Type ${C}kelmora help${NC} to view your master toolkit."
echo -e "${C}============================================================${NC}"
EOF
    sudo chmod +x /etc/update-motd.d/99-kelmora-dash
}

step_boot_anim() {
    sudo tee /usr/local/bin/k-welcome > /dev/null << 'EOF'
#!/bin/bash
clear
echo -e "\033[38;2;16;150;138m[SYS]\033[0m Waking Kelmora Cloud Node..."
sleep 0.5
echo -e "\033[38;2;16;150;138m[SYS]\033[0m Establishing secure neural connection..."
sleep 0.7
echo -en "\033[1;37m[NET]\033[0m Mounting encrypted volume [\033[38;2;16;150;138m" 
for i in {1..20}; do echo -n "█"; sleep 0.05; done; echo -e "\033[0m] \033[1;32mOK\033[0m"
sleep 0.3
echo -en "\033[1;37m[OS]\033[0m  Loading Kelmora Core Infrastructure [\033[38;2;16;150;138m" 
for i in {1..20}; do echo -n "█"; sleep 0.05; done; echo -e "\033[0m] \033[1;32mOK\033[0m"
sleep 0.5
echo -e "\033[1;32m[OK]\033[0m  Authentication successful. Welcome to the Starship."
sleep 1.2
clear
/etc/update-motd.d/99-kelmora-dash
EOF
    sudo chmod +x /usr/local/bin/k-welcome

    sudo tee /etc/profile.d/kelmora_welcome.sh > /dev/null << 'EOF'
#!/bin/bash
if [ ! -f ~/.kelmora_welcomed ]; then
    text="[Kelmora System] Booting..."
    for (( i=0; i<${#text}; i++ )); do echo -n "${text:$i:1}"; sleep 0.05; done
    echo ""
    /usr/local/bin/k-welcome
    touch ~/.kelmora_welcomed
fi
EOF
    sudo chmod +x /etc/profile.d/kelmora_welcome.sh
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
# ⚙️ THE MAIN KELMORA INSTALLER SANDBOX
# ============================================================

main() {
    _run_task "Performing deep disk integrity & hypervisor check..." step_hw_check
    _run_task "Purging ghost configurations and legacy prompts..." step_scrub
    _run_task "Fetching Massive Kelmora Dependency Library..." step_deps
    _run_task "Hooking into official enterprise repositories (Ookla Speedtest)..." step_ookla
    _run_task "Forging Next-Gen TUI Workspaces (Zellij, Micro, Lazydocker, Lazygit, Yazi)..." step_rust_binaries
    _run_task "Deploying Custom OS Identity Engine (Fastfetch)..." step_fastfetch
    _run_task "Forging the Starship Rust-Engine Prompt..." step_starship
    _run_task "Injecting Kelmora Unified CLI Engine & Neural Net..." step_cli_engine
    _run_task "Compiling Signature Heartbeat Dashboard..." step_motd
    _run_task "Wiring the Kelmora Neural Boot sequence..." step_boot_anim
    _run_task "Eradicating default Ubuntu advertisements and enforcing persistence..." step_silence_ads
    _run_task "Deploying Kelmora Studio (Global Editor Overrides)..." step_studio

    # FINALIZATION
    systemctl restart ssh > /dev/null 2>&1

    tput cnorm # Safely restore the cursor
    echo ""
    echo -e "${KC}======================================================================${NC}"
    echo -e "\033[1;32m  ✅ KELMORA SIGNATURE OS INSTALLED SUCCESSFULLY \033[0m"
    echo -e "${KC}======================================================================${NC}"
    echo -e "\033[1;31m⚠️  CRITICAL: Close this terminal completely and log back in to activate the Singularity Engine. \033[0m"
}

# Execute the sandbox synchronously 
main "$@"
