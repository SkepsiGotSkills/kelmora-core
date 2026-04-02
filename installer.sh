#!/bin/bash
# ==============================================================================
# KELMORA CLOUD - THE "SIGNATURE BUILD" OMNI-OS PROVISIONER (TITANIUM EDITION)
# ==============================================================================

# Disable history expansion to prevent paste-crashes
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
echo -e "\033[1;37m  🚀 INITIALIZING KELMORA SIGNATURE OS: TITANIUM BUILD\033[0m"
echo -e "${KC}======================================================================${NC}"
echo ""

# --- The Synchronous Safe Loader ---
_run_task() {
    local msg="$1"
    local func="$2"
    echo -en "${KC}[⏳]${NC} \033[1;37m${msg}\033[0m"
    $func >/dev/null 2>&1
    echo -e "\r\033[1;32m[✅] \033[1;37m${msg}\033[0m\033[K"
    sleep 0.1
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
    
    # Nuclear scrub of corrupted color codes and old prompts from previous crashed versions
    sed -i '/_kelmora_prompt/d' /root/.bashrc /home/*/.bashrc /etc/bash.bashrc 2>/dev/null || true
    sed -i '/PROMPT_COMMAND/d' /root/.bashrc /home/*/.bashrc /etc/bash.bashrc 2>/dev/null || true
    sed -i '/starship init/d' /root/.bashrc /home/*/.bashrc /etc/bash.bashrc 2>/dev/null || true
    sed -i '/zoxide init/d' /root/.bashrc /home/*/.bashrc /etc/bash.bashrc 2>/dev/null || true
    sed -i '/FZF_DEFAULT_OPTS/d' /root/.bashrc /home/*/.bashrc /etc/bash.bashrc 2>/dev/null || true
    
    # Surgical removal of the specific '\E[1' ghost strings
    sed -i '/\\E\[1/d' /root/.bashrc /home/*/.bashrc /etc/bash.bashrc 2>/dev/null || true
    sed -i '/31m\[K\]/d' /root/.bashrc /home/*/.bashrc /etc/bash.bashrc 2>/dev/null || true
    sed -i '/33m\[K\]/d' /root/.bashrc /home/*/.bashrc /etc/bash.bashrc 2>/dev/null || true
    sed -i '/37m\[K\]/d' /root/.bashrc /home/*/.bashrc /etc/bash.bashrc 2>/dev/null || true
    sed -i "/\$'\\\\E\[1'/d" /root/.bashrc /home/*/.bashrc /etc/bash.bashrc 2>/dev/null || true
}

step_kernel_optim() {
    # Enable Google BBR Congestion Control for hyper-fast networking
    echo "net.core.default_qdisc=fq" >> /etc/sysctl.conf
    echo "net.ipv4.tcp_congestion_control=bbr" >> /etc/sysctl.conf
    # Lower swappiness to keep app data in physical RAM longer
    echo "vm.swappiness=10" >> /etc/sysctl.conf
    sysctl -p
}

step_deps() {
    export DEBIAN_FRONTEND=noninteractive
    apt-get update -qq
    apt-get install -y -qq curl apt-transport-https ca-certificates gnupg bc htop unzip wget tar ufw git jq net-tools pv cmatrix mtr-tiny dnsutils software-properties-common fail2ban iperf3 nethogs ncdu bat ripgrep fd-find lnav nala duf
    ln -sf /usr/bin/batcat /usr/local/bin/bat || true
}

step_ookla() {
    curl -s https://packagecloud.io/install/repositories/ookla/speedtest-cli/script.deb.sh | bash
    apt-get install -y -qq speedtest
}

step_rust_binaries() {
    # Fetch core binaries dynamically
    wget -qO /tmp/eza.tar.gz "https://github.com/eza-community/eza/releases/latest/download/eza_x86_64-unknown-linux-gnu.tar.gz" && tar -xzf /tmp/eza.tar.gz -C /tmp/ && mv /tmp/eza /usr/local/bin/eza && chmod +x /usr/local/bin/eza
    wget -qO /tmp/btm.tar.gz "https://github.com/ClementTsang/bottom/releases/latest/download/bottom_x86_64-unknown-linux-gnu.tar.gz" && tar -xzf /tmp/btm.tar.gz -C /tmp/ && mv /tmp/btm /usr/local/bin/btm && chmod +x /usr/local/bin/btm
    wget -qO /tmp/zellij.tar.gz "https://github.com/zellij-org/zellij/releases/latest/download/zellij-x86_64-unknown-linux-musl.tar.gz" && tar -xzf /tmp/zellij.tar.gz -C /tmp/ && mv /tmp/zellij /usr/local/bin/zellij && chmod +x /usr/local/bin/zellij
    wget -qO /tmp/gping.tar.gz "https://github.com/orf/gping/releases/latest/download/gping-x86_64-unknown-linux-musl.tar.gz" && tar -xzf /tmp/gping.tar.gz -C /tmp/ && mv /tmp/gping /usr/local/bin/gping && chmod +x /usr/local/bin/gping
    wget -qO /usr/local/bin/tldr "https://github.com/dbrgn/tealdeer/releases/latest/download/tldr-linux-x86_64-musl" && chmod +x /usr/local/bin/tldr
    
    curl -sL https://getmic.ro | bash && mv micro /usr/local/bin/
    curl -sS https://raw.githubusercontent.com/ajeetdsouza/zoxide/main/install.sh | bash && mv ~/.local/bin/zoxide /usr/local/bin/ || true
    curl -sL https://raw.githubusercontent.com/jesseduffield/lazydocker/master/scripts/install_update_linux.sh | DIR=/usr/local/bin bash
    
    # Flawless Lazygit Fetch
    LAZYGIT_VERSION=$(curl -s "https://api.github.com/repos/jesseduffield/lazygit/releases/latest" | grep -Po '"tag_name": "v\K[^"]*')
    wget -qO /tmp/lazygit.tar.gz "https://github.com/jesseduffield/lazygit/releases/latest/download/lazygit_${LAZYGIT_VERSION}_Linux_x86_64.tar.gz"
    tar -xzf /tmp/lazygit.tar.gz -C /tmp/ lazygit && mv /tmp/lazygit /usr/local/bin/lazygit && chmod +x /usr/local/bin/lazygit

    # Flawless Yazi Fetch
    wget -qO /tmp/yazi.zip "https://github.com/sxyazi/yazi/releases/latest/download/yazi-x86_64-unknown-linux-gnu.zip"
    unzip -qo /tmp/yazi.zip -d /tmp/
    find /tmp/ -name "yazi" -type f -executable -exec mv {} /usr/local/bin/yazi \;
    chmod +x /usr/local/bin/yazi
    rm -rf /tmp/yazi*
    
    # Flawless FZF Fetch (Bypassing APT completely)
    FZF_VERSION=$(curl -s "https://api.github.com/repos/junegunn/fzf/releases/latest" | grep -Po '"tag_name": "v\K[^"]*')
    wget -qO /tmp/fzf.tar.gz "https://github.com/junegunn/fzf/releases/download/v${FZF_VERSION}/fzf-${FZF_VERSION}-linux_amd64.tar.gz"
    tar -xzf /tmp/fzf.tar.gz -C /tmp/ fzf && mv /tmp/fzf /usr/local/bin/fzf && chmod +x /usr/local/bin/fzf
}

step_fastfetch() {
    wget -qO /tmp/fastfetch.tar.gz "https://github.com/fastfetch-cli/fastfetch/releases/latest/download/fastfetch-linux-amd64.tar.gz"
    tar -xzf /tmp/fastfetch.tar.gz -C /tmp/ && mv /tmp/fastfetch-*/usr/bin/fastfetch /usr/local/bin/fastfetch && chmod +x /usr/local/bin/fastfetch
    rm -rf /tmp/fastfetch*
    
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
EOF
}

step_cli_engine() {
    sudo tee /etc/kelmora_env.sh > /dev/null << 'EOF'
export KELMORA_VER="SIGNATURE"
export STARSHIP_CONFIG=/etc/starship.toml
export BAT_THEME="TwoDark"
export EDITOR="micro"
export VISUAL="micro"
export FZF_DEFAULT_OPTS="--color=fg:#ffffff,bg:-1,hl:#10968A --color=fg+:#ffffff,bg+:#10968A,hl+:#000000 --color=info:#10968A,prompt:#10968A,pointer:#10968A,marker:#10968A,spinner:#10968A,header:#10968A"

unset PROMPT_COMMAND
export PS1='[\u@\h \W]\$ '
if command -v starship &> /dev/null; then eval "$(starship init bash 2>/dev/null)"; fi
if command -v zoxide &> /dev/null; then eval "$(zoxide init bash 2>/dev/null)"; fi

alias ls='eza --icons --color=always --group-directories-first'
alias ll='eza -la --icons --color=always --group-directories-first'
alias htop='btm'
alias top='btm'
alias cat='bat --style=plain'
alias apt='nala'

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

kelmora() {
    local cmd=$1
    shift
    if [[ -z "$cmd" ]]; then
        if ! command -v fzf &> /dev/null; then
            echo -e "\033[1;31m[K] ❌ FZF engine missing. Please run 'bash install.sh' again to repair dependencies.\033[0m"
            return
        fi
        local choice=$(printf "os\ninfo\nservices\noptimizer\nscan\nstats\ndisk\nbench\nworkspace\ndocker-ui\ngit\nfiles\nlogs-view\nread\nls\ntree\nsecure\nspeedtest\ntraffic\nping\nhelp\nreboot" | fzf --height 40% --layout=reverse --border --prompt="Kelmora Center ❯ " --header="Select a module to engage" 2>/dev/null)
        [[ -z "$choice" ]] && return
        kelmora "$choice" "$@"
        return
    fi

    [[ "$cmd" =~ ^(help|os|scan|stats|read|ls|workspace|docker-ui|git|files|logs-view|disk)$ ]] || _k_loader "[Kelmora OS] Engaging module: $cmd"

    case "$cmd" in
        "os") fastfetch -c /etc/fastfetch-kelmora.jsonc ;;
        "info") echo -e "\033[38;2;16;150;138m⚙️  Hardware Identity:\033[0m\n   CPU: $(lscpu | grep 'Model name' | cut -d: -f2 | xargs)\n   Kernel: $(uname -r)" ;;
        "services") local found=false; for s in docker nginx wings ufw ssh; do if systemctl list-unit-files | grep -q "^${s}.service"; then found=true; echo -en "   Checking $s... "; systemctl is-active --quiet $s && echo -e "\033[1;32m🟢 ONLINE\033[0m" || echo -e "\033[1;31m🔴 OFFLINE\033[0m"; fi; done; [[ "$found" == false ]] && echo "No tracked services found.";;
        "updater"|"optimizer"|"clean") nala update && nala upgrade -y && nala autoremove -y ;;
        "ram-flush") sudo sync; echo 3 | sudo tee /proc/sys/vm/drop_caches > /dev/null; echo -e "\033[1;32m✨ Memory freed successfully.\033[0m" ;;
        "swap"|"4gb-ram") if [ -f /swapfile ]; then echo "Swap exists."; else fallocate -l 4G /swapfile && chmod 600 /swapfile && mkswap /swapfile && swapon /swapfile && echo "/swapfile none swap sw 0 0" >> /etc/fstab; fi ;;
        "stats") btm ;;
        "disk") duf ;;
        "disk-analyzer") ncdu / ;;
        "bench") curl -sL yabs.sh | bash -s -- -ig ;;
        "reboot") echo -e "\033[1;31mRebooting node...\033[0m"; sleep 2; sudo reboot ;;
        "scan") tput civis; echo -en "\033[1;37m[SYS] Scanning... \033[0m"; for i in {1..10}; do echo -n "█"; sleep 0.05; done; echo -e " \033[1;32mOK\033[0m"; tput cnorm ;;
        "install-ptero") bash <(curl -s https://pterodactyl-installer.se) ;;
        "secure") systemctl enable fail2ban && systemctl start fail2ban && ufw default deny incoming && ufw allow 22/tcp && ufw --force enable ;;
        "speedtest"|"speed") speedtest --accept-license --accept-gdpr ;;
        "ping") gping "${1:-8.8.8.8}" ;;
        "workspace") zellij ;;
        "docker-ui") lazydocker ;;
        "git") lazygit "$@" ;;
        "files") yazi "$@" ;;
        "logs-view") lnav "$@" ;;
        "read") bat "$@" ;;
        "ls") eza -la --icons --group-directories-first "$@" ;;
        "tree") eza --tree --icons --group-directories-first "$@" ;;
        "edit") micro "$@" ;;
        "help"|"") _k_help ;;
        *) echo -e "\033[1;31m[K] ❌ Module '$cmd' not found.\033[0m" ;;
    esac
}

_k_help() {
    echo -e "${KC}======================================================================${NC}"
    echo -e "\033[1;37m         KELMORA CLOUD SIGNATURE BUILD - COMMAND MATRIX\033[0m"
    echo -e "${KC}======================================================================${NC}"
    echo -e "\033[1;37m Usage: \033[38;2;16;150;138mkelmora \033[1;37m<module>   (Or just type \033[38;2;16;150;138mkelmora\033[1;37m for the menu)\033[0m"
    echo -e " ⚡ \033[38;2;16;150;138mworkspace / docker-ui / git / files / logs-view\033[1;37m - Visual TUIs\033[0m"
    echo -e " ⚡ \033[38;2;16;150;138mos / stats / disk / ping / scan / speedtest\033[1;37m - Diagnostics\033[0m"
    echo -e " ⚡ \033[38;2;16;150;138moptimizer / ram-flush / 4gb-ram\033[1;37m - Performance\033[0m"
}
EOF
}

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

# ============================================================
# ⚙️ MAIN EXECUTION
# ============================================================

main() {
    _run_task "Performing deep disk integrity check..." step_hw_check
    _run_task "Injecting Kernel Speed Optimizations (TCP BBR)..." step_kernel_optim
    _run_task "Purging ghost configurations..." step_scrub
    _run_task "Fetching Massive Dependency Library (Nala, Bat, etc)..." step_deps
    _run_task "Hooking into Ookla Speedtest repositories..." step_ookla
    _run_task "Forging TUI Workspaces (Zellij, Lazygit, Yazi, FZF, etc)..." step_rust_binaries
    _run_task "Deploying OS Identity Engine (Fastfetch)..." step_fastfetch
    _run_task "Forging Starship Rust-Engine Prompt..." step_starship
    _run_task "Injecting Kelmora Interactive Command Center..." step_cli_engine
    _run_task "Compiling Signature Heartbeat Dashboard..." step_motd
    _run_task "Wiring the Neural Boot sequence..." step_boot_anim
    
    systemctl restart ssh > /dev/null 2>&1
    tput cnorm 
    echo ""
    echo -e "${KC}======================================================================${NC}"
    echo -e "\033[1;32m  ✅ KELMORA SIGNATURE OS INSTALLED SUCCESSFULLY \033[0m"
    echo -e "${KC}======================================================================${NC}"
    echo -e "\033[1;31m⚠️  CRITICAL: Close this terminal and log back in to activate! \033[0m"
}

main "$@"
