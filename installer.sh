#!/bin/bash
# ==============================================================================
# KELMORA CLOUD - UNIVERSAL PRODUCTION PROVISIONER (v11.0)
# ==============================================================================

if [[ $EUID -ne 0 ]]; then
   echo -e "\033[0;31m❌ Error: This script must be run as root (use sudo).\033[0m"
   exit 1
fi

clear
echo -e "\033[0;36m============================================================\033[0m"
echo -e "\033[1;32m  🚀 INITIALIZING KELMORA PRODUCTION OS DEPLOYMENT\033[0m"
echo -e "\033[0;36m============================================================\033[0m"

# 1. INSTALL UNIVERSAL DEPENDENCIES (Silent)
echo -e "\033[1;33m[1/5]\033[0m Verifying core dependencies (bc, curl, htop)..."
apt-get update -qq
apt-get install -y -qq bc curl htop > /dev/null 2>&1

# 2. PURGE OLD CONFIGS (Fixing the Syntax Error)
echo -e "\033[1;33m[2/5]\033[0m Deep cleaning legacy configurations..."
rm -f /usr/bin/kelmora-* /usr/local/bin/kelmora-* /bin/kelmora-* 2>/dev/null || true
rm -f /etc/sudoers.d/kelmora /etc/kelmora_env.sh 2>/dev/null || true

# 3. BUILD THE MASTER ENVIRONMENT (Bug-Free Functions)
echo -e "\033[1;33m[3/5]\033[0m Injecting Kelmora shell logic and animations..."

cat << 'EOF' | tee /etc/kelmora_env.sh > /dev/null
# ============================================================
# KELMORA CLOUD: GLOBAL SHELL ENVIRONMENT
# ============================================================

export PS1="\[\e[1;36m\][K] \[\e[1;32m\]\u@\h\[\e[0m\]:\[\e[1;34m\]\w\[\e[0m\]\$ "
export TMOUT=3600 
export HISTCONTROL=ignoreboth:erasedups 
alias rm='rm -i' 
alias cp='cp -i' 
alias mv='mv -i' 

# --- Animation Helper ---
_kelmora_spinner() {
    local pid=$1
    local delay=0.1
    local spinstr='|/-\'
    while [ "$(ps a | awk '{print $1}' | grep $pid)" ]; do
        local temp=${spinstr#?}
        printf " [%c]  " "$spinstr"
        local spinstr=$temp${spinstr%"$temp"}
        sleep $delay
        printf "\b\b\b\b\b\b"
    done
    printf "    \b\b\b\b"
}

# --- Bash Functions (Underscores ONLY to prevent syntax errors) ---

kelmora_clean() {
    echo -en "\033[1;33m🧹 Sweeping system cache and applying updates...\033[0m"
    (sudo apt-get update -qq && sudo apt-get dist-upgrade -y -qq && sudo apt-get autoremove -y -qq && sudo apt-get autoclean -qq) > /dev/null 2>&1 &
    _kelmora_spinner $!
    echo -e "\r\033[1;32m✨ Kelmora Cloud: OS Refreshed, Updated, and Optimized!\033[0m"
}

kelmora_audit() {
    echo -e "\033[1;36m🔍 Initiating Kelmora Security Sweep...\033[0m"
    sleep 0.5
    echo -en "\033[1;33m[1/3] Checking for unpassworded accounts: \033[0m"
    local empty_pw=$(sudo awk -F: '($2 == "") {print $1}' /etc/shadow)
    if [ -z "$empty_pw" ]; then echo -e "\033[0;32mPASS\033[0m"; else echo -e "\033[0;31mFAIL ($empty_pw)\033[0m"; fi
    sleep 0.5
    echo -en "\033[1;33m[2/3] Checking SSH Root configuration: \033[0m"
    if grep -q "^PermitRootLogin yes" /etc/ssh/sshd_config; then echo -e "\033[0;31mWARNING (Root Allowed)\033[0m"; else echo -e "\033[0;32mSECURE\033[0m"; fi
    sleep 0.5
    echo -e "\033[1;33m[3/3] Active Public Ports:\033[0m"
    sudo ss -tulpn | grep LISTEN | awk '{print "  👉 "$5" ("$7")"}'
    echo -e "\033[1;32m✅ Sweep Complete.\033[0m"
}

kelmora_services() {
    echo -e "\033[1;36m🚦 Universal Service Health Check:\033[0m"
    local found=false
    # Dynamically scans for standard VPS apps
    for s in docker nginx apache2 mysql mariadb postgresql wings ufw ssh php8.1-fpm; do
        if systemctl list-unit-files | grep -q "^${s}.service"; then
            found=true
            echo -en "   Checking $s... "
            if systemctl is-active --quiet $s; then
                echo -e "\r \033[0;32m🟢 $s is ONLINE and running.\033[0m"
            else
                echo -e "\r \033[0;31m🔴 $s is OFFLINE.\033[0m"
            fi
            sleep 0.1
        fi
    done
    if [ "$found" = false ]; then echo -e "   \033[1;33mNo standard tracked services found on this node.\033[0m"; fi
}

kelmora_swap() {
    echo -en "\033[1;33m⚙️  Allocating 4GB Emergency Swap Memory...\033[0m"
    if [ -f /swapfile ]; then
        echo -e "\r\033[1;34mℹ️  Kelmora Cloud: Swap file already exists on this node.\033[0m"
    else
        (sudo fallocate -l 4G /swapfile && sudo chmod 600 /swapfile && sudo mkswap /swapfile && sudo swapon /swapfile && echo "/swapfile none swap sw 0 0" | sudo tee -a /etc/fstab) > /dev/null 2>&1 &
        _kelmora_spinner $!
        echo -e "\r\033[1;32m✅ Kelmora Cloud: 4GB Swap Activated Successfully!\033[0m"
    fi
}

kelmora_secure() {
    echo -en "\033[1;33m🛡️  Locking down external ports (allowing 22, 80, 443)...\033[0m"
    (sudo ufw default deny incoming && sudo ufw default allow outgoing && sudo ufw allow 22/tcp && sudo ufw allow 80/tcp && sudo ufw allow 443/tcp && sudo ufw --force enable) > /dev/null 2>&1 &
    _kelmora_spinner $!
    echo -e "\r\033[1;32m🛡️  Kelmora Shield: ACTIVE. Server is secured.\033[0m"
}

kelmora_unsecure() {
    echo -e "\033[0;31m⚠️  WARNING: Dropping Kelmora Shield...\033[0m"
    sudo ufw disable > /dev/null 2>&1
    sudo ufw --force reset > /dev/null 2>&1
    echo -e "\033[1;31m🔓 Firewall Disabled. All ports open to the public.\033[0m"
}

kelmora_help() {
    echo -e "\033[1;36m============================================================\033[0m"
    echo -e "\033[1;33m              KELMORA CLOUD - MASTER TERMINAL\033[0m"
    echo -e "\033[1;36m============================================================\033[0m"
    echo -e " \033[1;32mkelmora-clean\033[0m     - \033[0;37mAnimated OS Update & Deep Junk Purge\033[0m"
    echo -e " \033[1;32mkelmora-services\033[0m  - \033[0;37mScan & View Local App Health\033[0m"
    echo -e " \033[1;32mkelmora-audit\033[0m     - \033[0;37mRun a 3-step security sweep\033[0m"
    echo -e " \033[1;32mkelmora-secure\033[0m    - \033[0;37mActivate Firewall (Allow Web/SSH)\033[0m"
    echo -e " \033[1;32mkelmora-unsecure\033[0m  - \033[0;37mDisable Firewall (Reset all rules)\033[0m"
    echo -e " \033[1;32mkelmora-swap\033[0m      - \033[0;37mAllocate 4GB Emergency RAM\033[0m"
    echo -e " \033[1;32mkelmora-stats\033[0m     - \033[0;37mView live hardware usage (htop)\033[0m"
    echo -e " \033[1;32mkelmora-speed\033[0m     - \033[0;37mTest 10Gbps backbone speeds\033[0m"
    echo -e " \033[1;32mkelmora-bench\033[0m     - \033[0;37mRun deep performance benchmark\033[0m"
    echo -e " \033[1;32mkelmora-info\033[0m      - \033[0;37mPrint CPU & Kernel identity\033[0m"
    echo -e " \033[1;32mkelmora-bigfiles\033[0m  - \033[0;37mHunt down storage hogs\033[0m"
    echo -e " \033[1;32mkelmora-logs\033[0m      - \033[0;37mPrint last 20 critical system errors\033[0m"
    echo -e " \033[1;32mkelmora-ports\033[0m     - \033[0;37mList all active listening ports\033[0m"
    echo -e "\033[1;36m============================================================\033[0m"
}

# --- Aliases mapping the hyphens to the safe underscores ---
alias kelmora-clean='kelmora_clean'
alias kelmora-audit='kelmora_audit'
alias kelmora-services='kelmora_services'
alias kelmora-swap='kelmora_swap'
alias kelmora-secure='kelmora_secure'
alias kelmora-unsecure='kelmora_unsecure'
alias kelmora-help='kelmora_help'
alias kelmora-stats='htop'
alias kelmora-speed='curl -s https://raw.githubusercontent.com/sivel/speedtest-cli/master/speedtest.py | python3 -'
alias kelmora-bench='curl -sL yabs.sh | bash -s -- -ig'
alias kelmora-info='echo -e "\033[1;34m⚙️  Hardware Identity:\033[0m\n   CPU: $(lscpu | grep "Model name" | sed "s/Model name: //" | xargs)\n   Kernel: $(uname -r)\n   Architecture: $(uname -m)"'
alias kelmora-logs='sudo journalctl -p 3 -xb | tail -n 20'
alias kelmora-bigfiles='echo -e "\033[1;36m📁 Hunting top 20 largest files/folders...\033[0m" && sudo du -ah / 2>/dev/null | sort -rh | head -n 20'
alias kelmora-ports='sudo ss -tulpn | grep LISTEN'
EOF

# 4. BUILD THE UNIVERSAL MOTD DASHBOARD
echo -e "\033[1;33m[4/5]\033[0m Compiling Universal Heartbeat Dashboard..."

cat << 'EOF' | sudo tee /etc/update-motd.d/99-kelmora-dash > /dev/null
#!/bin/bash
C='\033[0;36m'; G='\033[0;32m'; Y='\033[1;33m'; R='\033[0;31m'; NC='\033[0m'; W='\033[1;37m'

UP=$(uptime -p | sed 's/up //'); LD=$(cat /proc/loadavg | awk '{print $1}')
MEM_U=$(free -m | awk '/Mem:/ { print $3 }'); MEM_T=$(free -m | awk '/Mem:/ { print $2 }')
DSK_P=$(df / | awk 'NR==2 {print $5}' | sed 's/%//'); DSK_U=$(df -h / | awk 'NR==2 {print $3}')
IP=$(hostname -I | awk '{print $1}')
TIME=$(date +"%A, %B %d, %Y - %T %Z")

# Universal Service Detection for the MOTD
APP_STATUS=""
if systemctl is-active --quiet wings; then APP_STATUS="🦖 Wings: ${G}ONLINE${NC}"
elif systemctl is-active --quiet docker; then APP_STATUS="🐳 Docker: ${G}ONLINE${NC}"
elif systemctl is-active --quiet nginx; then APP_STATUS="🌐 Nginx: ${G}ONLINE${NC}"
elif systemctl is-active --quiet apache2; then APP_STATUS="🌐 Apache: ${G}ONLINE${NC}"
else APP_STATUS="⚙️ System: ${G}ONLINE${NC}"; fi

echo -e "${C}============================================================${NC}"
# Use 'bc' safely. If bc fails, suppress the error so the MOTD doesn't crash.
if command -v bc > /dev/null 2>&1; then
    if (( $(echo "$LD > 8.0" | bc -l) )); then echo -e " 🔥 ${R}SYSTEM ALERT: Extreme CPU throttling detected ($LD)!${NC}"; fi
fi
if [ "$DSK_P" -gt 90 ]; then echo -e " 🚨 ${R}SYSTEM ALERT: Storage is critically full ($DSK_P% Used)!${NC}"; fi

echo -e "${C}   _  __     _                                 ${NC}"
echo -e "${C}  | |/ /___ | | _ __ ___    ___   _ __  __ _   ${NC}"
echo -e "${C}  | ' // _ \| || '_ ' _ \  / _ \ | '__|/ _' |  ${NC}"
echo -e "${C}  | . \  __/| || | | | | || (_) || |  | (_| |  ${NC}"
echo -e "  |_|\_\___||_||_| |_| |_| \___/ |_|   \__,_|  ${NC}"
echo -e "          ${G}Powered by Kelmora Cloud Hosting${NC}"
echo -e "${C}============================================================${NC}"

echo -e " ${Y}📡 Live Telemetry:${NC}       ${W}$TIME${NC}"
echo -e "  🚀 Uptime: ${G}$UP${NC}"
echo -e "  ⚡ Load:   ${G}$LD${NC}             🌐 IP: ${G}$IP${NC}"
echo -e "  🧠 Memory: ${G}$MEM_U / $MEM_T MB${NC}   🗄️ Disk: ${G}$DSK_U / $DSK_P% Used${NC}"
echo -e "  $APP_STATUS"
echo -e "${C}------------------------------------------------------------${NC}"
echo -e " 🎫 Support: ${C}billing.kelmora.cloud${NC} | 💬 Discord: ${C}kelmora${NC}"
echo -e "${C}============================================================${NC}"
echo -e " ✨ Tip: Type ${G}kelmora-help${NC} to view your toolset."
echo -e "${C}============================================================${NC}"
EOF
chmod +x /etc/update-motd.d/99-kelmora-dash

# 5. NUCLEAR SILENCING OF UBUNTU ADS
echo -e "\033[1;33m[5/5]\033[0m Eradicating default Ubuntu advertisements and enforcing persistence..."

# Enforce environment loading
sed -i '/kelmora_env.sh/d' /etc/bash.bashrc
echo "source /etc/kelmora_env.sh" >> /etc/bash.bashrc

# Nuke ALL default Ubuntu MOTD spam
chmod -x /etc/update-motd.d/10-help-text /etc/update-motd.d/50-motd-news /etc/update-motd.d/80-livepatch /etc/update-motd.d/50-landscape-sysinfo /etc/update-motd.d/90-updates-available /etc/update-motd.d/91-release-upgrade /etc/update-motd.d/95-hwe-eol /etc/update-motd.d/97-overlayroot 2>/dev/null || true

# Disable the update manager prompts entirely
sed -i 's/Prompt=.*/Prompt=never/' /etc/update-manager/release-upgrades 2>/dev/null || true

# Silence SSH default MOTD
sed -i 's/^PrintMotd.*/PrintMotd no/' /etc/ssh/sshd_config 2>/dev/null || true
truncate -s 0 /etc/motd 2>/dev/null || true

# 6. ACTIVATE
systemctl restart ssh

echo -e "\033[0;36m============================================================\033[0m"
echo -e "\033[1;32m  ✅ KELMORA UNIVERSAL OS INSTALLED SUCCESSFULLY\033[0m"
echo -e "\033[0;36m============================================================\033[0m"
echo -e "\033[0;37mPlease log out and log back in to activate the Living OS.\033[0m"
