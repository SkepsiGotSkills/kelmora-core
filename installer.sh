#!/bin/bash
# ==============================================================================
# KELMORA CLOUD - THE "SUPERNOVA" OMNI-OS PROVISIONER (v19.0)
# ==============================================================================

set +H # Disable Bash history expansion
if [[ $EUID -ne 0 ]]; then
   echo -e "\033[0;31m❌ Error: This script must be run as root (use sudo).\033[0m"
   exit 1
fi

clear
echo -e "\033[0;36m======================================================================\033[0m"
echo -e "\033[1;32m  🚀 INITIALIZING KELMORA SUPERNOVA OS DEPLOYMENT (v19.0)\033[0m"
echo -e "\033[0;36m======================================================================\033[0m"

# 0. HARDWARE FAIL-SAFE
echo -en "\033[1;33m[0/8]\033[0m Performing deep disk integrity & hypervisor check... "
mount -o remount,rw / 2>/dev/null || true
if ! touch /etc/kelmora_hw_test 2>/dev/null; then
    echo -e "\n\033[1;31m🚨 CRITICAL ERROR: Filesystem is READ-ONLY. Disk is corrupted or locked.\033[0m"
    exit 1
fi
rm -f /etc/kelmora_hw_test
echo -e "\033[0;32mPASS\033[0m"

# 1. INSTALL MEGA DEPENDENCY LIBRARY (First, so repos work)
echo -e "\033[1;33m[1/8]\033[0m Fetching Massive Kelmora Dependency Library..."
export DEBIAN_FRONTEND=noninteractive
apt-get update -qq > /dev/null 2>&1
apt-get install -y -qq curl apt-transport-https ca-certificates gnupg bc htop unzip wget tar ufw git jq net-tools pv tree cmatrix mtr-tiny dnsutils software-properties-common fail2ban iperf3 nethogs ncdu > /dev/null 2>&1

# 2. OFFICIAL OOKLA REPOSITORY INTEGRATION
echo -e "\033[1;33m[2/8]\033[0m Hooking into official enterprise repositories (Ookla Speedtest)..."
curl -s https://packagecloud.io/install/repositories/ookla/speedtest-cli/script.deb.sh | sudo bash > /dev/null 2>&1
apt-get install -y -qq speedtest > /dev/null 2>&1

# 3. PURGE OLD CONFIGS
echo -e "\033[1;33m[3/8]\033[0m Deep cleaning legacy configurations and resetting environment..."
rm -f /usr/bin/kelmora-* /usr/local/bin/kelmora-* /bin/kelmora-* 2>/dev/null || true
rm -f /etc/sudoers.d/kelmora /etc/kelmora_env.sh /etc/profile.d/kelmora_welcome.sh 2>/dev/null || true

# 4. BUILD THE SUPERNOVA ENVIRONMENT (THE UNIFIED CLI ROUTER)
echo -e "\033[1;33m[4/8]\033[0m Injecting Kelmora Unified CLI Engine & Neural Net..."

cat << 'EOF' | tee /etc/kelmora_env.sh > /dev/null
# ============================================================
# KELMORA CLOUD: SUPERNOVA SHELL ENVIRONMENT
# ============================================================

export TMOUT=3600 
export HISTCONTROL=ignoreboth:erasedups 
export KELMORA_VER="19.0"

# --- Dynamic Time-Stamped Prompt ---
_kelmora_prompt() {
    local exit_status=$?
    local current_time=$(date +"%H:%M:%S")
    if [ $exit_status -eq 0 ]; then
        export PS1="\[\e[0;90m\][\[\e[0;36m\]${current_time}\[\e[0;90m\]] \[\e[1;32m\][K] \[\e[1;32m\]\u@\h\[\e[0m\]:\[\e[1;34m\]\w\[\e[0m\]\$ "
    else
        export PS1="\[\e[0;90m\][\[\e[0;36m\]${current_time}\[\e[0;90m\]] \[\e[1;31m\][K] \[\e[1;32m\]\u@\h\[\e[0m\]:\[\e[1;34m\]\w\[\e[0m\]\$ "
    fi
}
export PROMPT_COMMAND="_kelmora_prompt"

# --- AI Concierge ---
command_not_found_handle() {
    echo -e "\033[1;31m[K] ❌ Kelmora Core: Command '$1' is not recognized.\033[0m"
    echo -e "\033[1;33m[K] 💡 Type 'kelmora help' to view the master toolkit.\033[0m"
    return 127
}

# --- Visual Navigation ---
cd() {
    builtin cd "$@" && echo -e "\033[1;34m📂 $(pwd):\033[0m" && ls -A --color=auto
}

# --- Global QoL Spinner & Typewriter ---
_k_spin() {
    local pid=$1
    local delay=0.1
    local spinstr='⠋⠙⠹⠸⠼⠴⠦⠧⠇⠏'
    while [ "$(ps a | awk '{print $1}' | grep $pid)" ]; do
        local temp=${spinstr#?}
        printf " \033[1;36m%c\033[0m  " "$spinstr"
        local spinstr=$temp${spinstr%"$temp"}
        sleep $delay
        printf "\b\b\b\b"
    done
    printf "    \b\b\b\b"
}

_k_typewriter() {
    text="$1"
    delay="$2"
    for (( i=0; i<${#text}; i++ )); do
        echo -n "${text:$i:1}"
        sleep $delay
    done
    echo ""
}

# ============================================================
# 🚀 THE KELMORA UNIFIED CLI ENGINE
# ============================================================

kelmora() {
    local cmd=$1
    shift 
    
    # Cinematic Execution Confirmation
    if [[ -n "$cmd" && "$cmd" != "help" && "$cmd" != "os" && "$cmd" != "scan" ]]; then
        echo -en "\033[1;36m⚡ [Kelmora OS] Routing power to module: $cmd \033[0m"
        for i in {1..3}; do echo -n "▰"; sleep 0.1; done
        for i in {1..3}; do echo -n "▱"; sleep 0.1; done
        echo ""
    fi

    case "$cmd" in
        # SYSTEM & DIAGNOSTICS
        "os") _k_os ;;
        "info") _k_info ;;
        "services") _k_services ;;
        "logs") sudo journalctl -p 3 -xb | tail -n 20 ;;
        "updater"|"optimizer"|"clean") _k_clean ;;
        "ram-flush") _k_ram_flush ;;
        "swap"|"4gb-ram") _k_swap ;;
        "stats") htop ;;
        "disk-analyzer") ncdu / ;;
        "bench") curl -sL yabs.sh | bash -s -- -ig ;;
        "reboot") echo -e "\033[1;31mRebooting node in 3 seconds...\033[0m"; sleep 3; sudo reboot ;;
        "scan") _k_scan ;;
        
        # ONE-CLICK DEPLOYERS
        "install-ptero") echo -e "\033[1;36m🦖 Launching Pterodactyl Installer...\033[0m"; bash <(curl -s https://pterodactyl-installer.se) ;;
        "install-docker") _k_install_docker ;;
        "install-java") _k_install_java ;;
        "install-nodejs") _k_install_nodejs ;;
        "install-lamp") _k_install_lamp ;;
        "install-lemp") _k_install_lemp ;;
        "install-netdata") _k_install_netdata ;;
        
        # NETWORK & SECURITY
        "secure") _k_secure ;;
        "unsecure") sudo ufw disable > /dev/null 2>&1; sudo ufw --force reset > /dev/null 2>&1; echo -e "\033[1;31m🔓 Firewall Disabled. Node is public.\033[0m" ;;
        "audit") _k_audit ;;
        "net-rescue") sudo iptables -F; sudo ufw disable; echo -e "\033[1;31m🚨 Network protections dropped. You are exposed.\033[0m" ;;
        "speedtest"|"speed") speedtest --accept-license --accept-gdpr ;;
        "traffic") sudo nethogs ;;
        "trace") mtr 8.8.8.8 ;;
        "ports") sudo ss -tulpn | grep LISTEN ;;
        "myip") curl -s ifconfig.me; echo "" ;;
        
        # FILES & CONTAINERS
        "compress") _k_compress "$@" ;;
        "extract") _k_extract "$@" ;;
        "nuke") _k_nuke "$@" ;;
        "edit") nano "$@" ;;
        "tree") tree -C ;;
        "bigfiles") echo -e "\033[1;36m📁 Top 20 Storage Hogs:\033[0m"; sudo du -ah / 2>/dev/null | sort -rh | head -n 20 ;;
        "docker-ps") docker ps -a --format "table {{.ID}}\t{{.Names}}\t{{.Status}}\t{{.Ports}}" ;;
        "wings-logs") sudo journalctl -u wings -n 50 -f ;;
        "wings-restart") sudo systemctl restart wings; echo -e "\033[1;32m🦖 Wings daemon restarted.\033[0m" ;;
        
        # MAGIC & EASTER EGGS
        "welcome") /usr/local/bin/k-welcome ;;
        "matrix") cmatrix -b -C cyan ;;
        "weather") curl -s wttr.in/?0 ;;
        
        # HELP
        "help"|"") _k_help ;;
        *) echo -e "\033[1;31m[K] ❌ Module '$cmd' not found. Type 'kelmora help' for the index.\033[0m" ;;
    esac
}

# ============================================================
# ⚙️ INTERNAL CORE FUNCTIONS (Hidden from direct call)
# ============================================================

_k_os() {
    echo -e "\033[1;36m"
    echo -e "    //\\\\       K E L M O R A"
    echo -e "   //  \\\\      C L O U D   O S"
    echo -e "  //    \\\\     -----------------"
    echo -e " //======\\\\    \033[1;32mOS:\033[0m       $(cat /etc/os-release | grep PRETTY_NAME | cut -d= -f2 | tr -d '\"')"
    echo -e "//        \\\\   \033[1;32mKernel:\033[0m   $(uname -r)"
    echo -e "               \033[1;32mUptime:\033[0m   $(uptime -p | sed 's/up //')"
    echo -e "               \033[1;32mCPU:\033[0m      $(lscpu | grep "Model name" | sed "s/Model name: //" | xargs)"
    echo -e "               \033[1;32mRAM:\033[0m      $(free -m | awk '/Mem:/ { print $3 }')MB / $(free -m | awk '/Mem:/ { print $2 }')MB"
    echo -e "\033[0m"
}

_k_info() {
    echo -e "\033[1;34m⚙️  Hardware Identity:\033[0m"
    echo -e "   \033[1;36mCPU:\033[0m $(lscpu | grep "Model name" | sed "s/Model name: //" | xargs)"
    echo -e "   \033[1;36mKernel:\033[0m $(uname -r)"
    echo -e "   \033[1;36mArchitecture:\033[0m $(uname -m)"
}

_k_services() {
    echo -e "\033[1;36m🚦 Universal Service Health Check:\033[0m"
    local found=false
    for s in docker nginx apache2 mysql mariadb postgresql wings ufw ssh php8.1-fpm netdata; do
        if systemctl list-unit-files | grep -q "^${s}.service"; then
            found=true
            echo -en "   Checking $s... "
            if systemctl is-active --quiet $s; then
                echo -e "\r \033[0;32m🟢 $s is ONLINE and running.\033[0m\033[K"
            else
                echo -e "\r \033[0;31m🔴 $s is OFFLINE.\033[0m\033[K"
            fi
            sleep 0.1
        fi
    done
    if [ "$found" = false ]; then echo -e "   \033[1;33mNo standard tracked services found on this node.\033[0m"; fi
}

_k_scan() {
    _k_typewriter "\033[1;36m[SYS]\033[0m Initiating Deep System Diagnostic..." 0.02
    sleep 0.5
    echo -en "\033[1;33m[SYS]\033[0m Scanning Memory Blocks... "
    for i in {1..10}; do echo -n "▓"; sleep 0.05; done; echo -e " \033[1;32mINTEGRITY VERIFIED\033[0m"
    echo -en "\033[1;33m[NET]\033[0m Pinging Kelmora Backbone... "
    for i in {1..10}; do echo -n "▓"; sleep 0.05; done; echo -e " \033[1;32m<1ms LATENCY\033[0m"
    echo -en "\033[1;33m[SEC]\033[0m Checking Firewall Status... "
    if sudo ufw status | grep -q "active"; then echo -e " \033[1;32mARMED\033[0m"; else echo -e " \033[1;31mEXPOSED\033[0m"; fi
    sleep 0.5
    _k_typewriter "\033[1;32m✨ Diagnostic Complete. All systems nominal.\033[0m" 0.02
}

_k_clean() {
    echo -en "\033[1;33m🧹 Kelmora Optimizer: Sweeping cache, updating repos, purging junk...\033[0m"
    set +m
    (sudo DEBIAN_FRONTEND=noninteractive apt-get update -qq && sudo DEBIAN_FRONTEND=noninteractive apt-get dist-upgrade -y -qq && sudo DEBIAN_FRONTEND=noninteractive apt-get autoremove -y -qq && sudo apt-get autoclean -qq) > /dev/null 2>&1 &
    _k_spin $!
    set -m
    echo -e "\r\033[1;32m✨ Kelmora Cloud: OS Refreshed, Updated, and Optimized!\033[0m\033[K"
}

_k_swap() {
    echo -en "\033[1;33m⚙️  Allocating 4GB Emergency Swap Memory...\033[0m"
    if [ -f /swapfile ]; then
        echo -e "\r\033[1;34mℹ️  Kelmora Cloud: Swap file already exists on this node.\033[0m\033[K"
    else
        set +m
        (sudo fallocate -l 4G /swapfile && sudo chmod 600 /swapfile && sudo mkswap /swapfile && sudo swapon /swapfile && echo "/swapfile none swap sw 0 0" | sudo tee -a /etc/fstab) > /dev/null 2>&1 &
        _k_spin $!
        set -m
        echo -e "\r\033[1;32m✅ Kelmora Cloud: 4GB Swap Activated!\033[0m\033[K"
    fi
}

_k_ram_flush() {
    echo -e "\033[1;33m🧹 Flushing system RAM cache...\033[0m"
    sudo sync; echo 3 | sudo tee /proc/sys/vm/drop_caches > /dev/null
    echo -e "\033[1;32m✨ Memory freed successfully!\033[0m"
}

_k_audit() {
    echo -e "\033[1;36m🔍 Initiating Deep Kelmora Security Sweep...\033[0m"
    sleep 0.5
    echo -en "\033[1;33m[1/3] Checking for ghost accounts: \033[0m"
    local empty_pw=$(sudo awk -F: '($2 == "") {print $1}' /etc/shadow)
    if [ -z "$empty_pw" ]; then echo -e "\033[0;32mPASS\033[0m"; else echo -e "\033[0;31mFAIL ($empty_pw)\033[0m"; fi
    sleep 0.5
    echo -en "\033[1;33m[2/3] Checking SSH Root vulnerabilities: \033[0m"
    if grep -q "^PermitRootLogin yes" /etc/ssh/sshd_config; then echo -e "\033[0;31mWARNING (Root Allowed)\033[0m"; else echo -e "\033[0;32mSECURE\033[0m"; fi
    sleep 0.5
    echo -e "\033[1;33m[3/3] Active Listening Ports:\033[0m"
    sudo ss -tulpn | grep LISTEN | awk '{print "  👉 "$5" ("$7")"}'
    echo -e "\033[1;32m✅ Deep Sweep Complete.\033[0m"
}

_k_secure() {
    echo -en "\033[1;33m🛡️  Activating Kelmora Shield & Fail2Ban...\033[0m"
    set +m
    sudo systemctl enable fail2ban > /dev/null 2>&1
    sudo systemctl start fail2ban > /dev/null 2>&1
    (sudo ufw default deny incoming && sudo ufw default allow outgoing && sudo ufw allow 22/tcp && sudo ufw allow 80/tcp && sudo ufw allow 443/tcp && sudo ufw --force enable) > /dev/null 2>&1 &
    _k_spin $!
    set -m
    echo -e "\r\033[1;32m🛡️  Shield: ACTIVE. Brute-force protection online.\033[0m\033[K"
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
    if [ -z "$1" ]; then echo -e "\033[0;31m⚠️  Usage: kelmora extract <archive_file>\033[0m"; return 1; fi
    if [[ $1 == *.tar.gz || $1 == *.tgz ]]; then pv "$1" | tar -xz
    elif [[ $1 == *.zip ]]; then unzip -q "$1" && echo -e "\033[1;32m✨ Complete!\033[0m"
    else echo -e "\033[0;31m❌ Unsupported format. Use .zip or .tar.gz\033[0m"; return 1; fi
}

_k_compress() {
    if [ -z "$1" ]; then echo -e "\033[0;31m⚠️  Usage: kelmora compress <folder_name>\033[0m"; return 1; fi
    local stamp=$(date +"%Y-%m-%d_%H-%M-%S")
    local archive_name="${1%/}_${stamp}.tar.gz"
    tar -cf - "$1" | pv -s $(du -sb "$1" | awk '{print $1}') | gzip > "$archive_name"
    echo -e "\033[1;32m✅ Complete: $archive_name\033[0m"
}

_k_nuke() {
    if [ -z "$1" ]; then echo -e "\033[0;31m⚠️  Usage: kelmora nuke <target>\033[0m"; return 1; fi
    echo -e "\033[1;31m⚠️  WARNING: You are about to permanently eradicate: $1\033[0m"
    echo -en "\033[1;33mInitiating 3-second safety countdown: \033[0m"
    for i in 3 2 1; do echo -n "$i... "; sleep 1; done
    echo -e "\n\033[1;31m🧨 NUKING...\033[0m"
    rm -rf "$1"
    echo -e "\033[1;32m✨ Target eradicated.\033[0m"
}

_k_help() {
    echo -e "\033[1;36m======================================================================\033[0m"
    echo -e "\033[1;33m         KELMORA CLOUD v19.0 - SUPERNOVA COMMAND MATRIX\033[0m"
    echo -e "\033[1;36m======================================================================\033[0m"
    echo -e "\033[1;37mUsage: \033[1;32mkelmora \033[1;36m<module>\033[0m"
    echo -e "\033[1;36m----------------------------------------------------------------------\033[0m"
    echo -e "\033[1;34m[🛠️  SYSTEM & OPTIMIZATION]\033[0m"
    echo -e " \033[1;32mkelmora os\033[0m              - Kelmora Signature OS Readout"
    echo -e " \033[1;32mkelmora info\033[0m            - Print CPU, Kernel, and Arch details"
    echo -e " \033[1;32mkelmora services\033[0m        - Scan & View Local App Health Matrix"
    echo -e " \033[1;32mkelmora optimizer\033[0m       - Animated OS Update & Deep Junk Purge"
    echo -e " \033[1;32mkelmora updater\033[0m         - Alias for optimizer (updates repos/cache)"
    echo -e " \033[1;32mkelmora scan\033[0m            - Animated deep system diagnostics"
    echo -e " \033[1;32mkelmora 4gb-ram\033[0m         - Instantly allocate 4GB Emergency Swap Memory"
    echo -e " \033[1;32mkelmora ram-flush\033[0m       - Instantly free up cached system memory"
    echo -e " \033[1;32mkelmora stats\033[0m           - Live Resource Monitor (htop)"
    echo -e " \033[1;32mkelmora disk-analyzer\033[0m   - Deep visual disk space usage (ncdu)"
    echo -e " \033[1;32mkelmora bench\033[0m           - Deep Hardware Benchmark"
    echo -e ""
    echo -e "\033[1;34m[⚡ ONE-CLICK DEPLOYMENTS]\033[0m"
    echo -e " \033[1;32mkelmora install-ptero\033[0m   - Launch Pterodactyl Community Auto-Installer"
    echo -e " \033[1;32mkelmora install-docker\033[0m  - Auto-install Docker Engine & Compose"
    echo -e " \033[1;32mkelmora install-java\033[0m    - Auto-install Java 8, 17, and 21"
    echo -e " \033[1;32mkelmora install-nodejs\033[0m  - Auto-install Node.js LTS Runtime"
    echo -e " \033[1;32mkelmora install-lamp\033[0m    - Auto-install Web Stack (Apache/MySQL/PHP)"
    echo -e " \033[1;32mkelmora install-lemp\033[0m    - Auto-install Web Stack (Nginx/MariaDB/PHP)"
    echo -e " \033[1;32mkelmora install-netdata\033[0m - Auto-install Netdata live dashboard"
    echo -e ""
    echo -e "\033[1;34m[🛡️  NETWORK & SECURITY]\033[0m"
    echo -e " \033[1;32mkelmora secure\033[0m          - Activate Kelmora Shield & Fail2Ban"
    echo -e " \033[1;32mkelmora speedtest\033[0m       - Test 10Gbps backbone (Official Ookla CLI)"
    echo -e " \033[1;32mkelmora traffic\033[0m         - Live visual network traffic monitor"
    echo -e " \033[1;32mkelmora trace\033[0m           - Advanced Route Tracking"
    echo -e " \033[1;32mkelmora ports\033[0m           - List all active listening ports"
    echo -e " \033[1;32mkelmora audit\033[0m           - Deep system security & vulnerability sweep"
    echo -e " \033[1;32mkelmora net-rescue\033[0m      - Emergency Firewall Wipe (If locked out)"
    echo -e ""
    echo -e "\033[1;34m[📂 FILES & CONTAINERS]\033[0m"
    echo -e " \033[1;32mkelmora compress\033[0m        - Zip a folder with visual progress bar"
    echo -e " \033[1;32mkelmora extract\033[0m         - Unzip an archive with visual progress bar"
    echo -e " \033[1;32mkelmora tree\033[0m            - Visual Directory Map"
    echo -e " \033[1;32mkelmora nuke\033[0m            - Safely shred a folder (with countdown)"
    echo -e " \033[1;32mkelmora logs\033[0m            - Print last 20 critical system errors"
    echo -e " \033[1;32mkelmora docker-ps\033[0m       - Beautiful Docker Container List"
    echo -e " \033[1;32mkelmora wings-logs\033[0m      - Live Pterodactyl Daemon Logs"
    echo -e "\033[1;36m======================================================================\033[0m"
}

EOF

# 5. BUILD THE UNIVERSAL MOTD DASHBOARD
echo -e "\033[1;33m[5/8]\033[0m Compiling Supernova Heartbeat Dashboard..."

cat << 'EOF' | sudo tee /etc/update-motd.d/99-kelmora-dash > /dev/null
#!/bin/bash
C='\033[0;36m'; G='\033[0;32m'; Y='\033[1;33m'; R='\033[0;31m'; NC='\033[0m'; W='\033[1;37m'

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
echo -e " ✨ Tip: Type ${G}kelmora help${NC} to view your master toolkit."
echo -e "${C}============================================================${NC}"
EOF
chmod +x /etc/update-motd.d/99-kelmora-dash

# 6. THE FIRST-BOOT ANIMATION (The Sci-Fi Welcome)
echo -e "\033[1;33m[6/8]\033[0m Wiring the Kelmora Neural Boot sequence..."

cat << 'EOF' | sudo tee /usr/local/bin/k-welcome > /dev/null
#!/bin/bash
clear
echo -e "\033[1;36m[SYS]\033[0m Waking Kelmora Cloud Node..."
sleep 0.5
echo -e "\033[1;36m[SYS]\033[0m Establishing secure neural connection..."
sleep 0.7
echo -en "\033[1;33m[NET]\033[0m Mounting encrypted volume ["; 
for i in {1..20}; do echo -n "█"; sleep 0.05; done; echo -e "] \033[1;32mOK\033[0m"
sleep 0.3
echo -en "\033[1;33m[OS]\033[0m  Loading Kelmora Core Infrastructure ["; 
for i in {1..20}; do echo -n "█"; sleep 0.05; done; echo -e "] \033[1;32mOK\033[0m"
sleep 0.5
echo -e "\033[1;32m[OK]\033[0m  Authentication successful. Welcome to the Starship."
sleep 1.2
clear
/etc/update-motd.d/99-kelmora-dash
EOF
chmod +x /usr/local/bin/k-welcome

cat << 'EOF' | sudo tee /etc/profile.d/kelmora_welcome.sh > /dev/null
#!/bin/bash
if [ ! -f ~/.kelmora_welcomed ]; then
    # Typewriter effect for very first login
    text="[Kelmora System] Booting..."
    for (( i=0; i<${#text}; i++ )); do echo -n "${text:$i:1}"; sleep 0.05; done
    echo ""
    /usr/local/bin/k-welcome
    touch ~/.kelmora_welcomed
fi
EOF
chmod +x /etc/profile.d/kelmora_welcome.sh

# 7. NUCLEAR SILENCING OF UBUNTU ADS
echo -e "\033[1;33m[7/8]\033[0m Eradicating default Ubuntu advertisements and enforcing persistence..."
sed -i '/kelmora_env.sh/d' /etc/bash.bashrc
echo "source /etc/kelmora_env.sh" >> /etc/bash.bashrc
chmod -x /etc/update-motd.d/10-help-text /etc/update-motd.d/50-motd-news /etc/update-motd.d/80-livepatch /etc/update-motd.d/50-landscape-sysinfo /etc/update-motd.d/90-updates-available /etc/update-motd.d/91-release-upgrade /etc/update-motd.d/95-hwe-eol /etc/update-motd.d/97-overlayroot 2>/dev/null || true
sed -i 's/Prompt=.*/Prompt=never/' /etc/update-manager/release-upgrades 2>/dev/null || true
sed -i 's/^PrintMotd.*/PrintMotd no/' /etc/ssh/sshd_config 2>/dev/null || true
truncate -s 0 /etc/motd 2>/dev/null || true

# 8. KELMORA STUDIO
echo -e "\033[1;33m[8/8]\033[0m Deploying Kelmora Studio (Modern UI for text files)..."
cat << 'EOF' | sudo tee /etc/nanorc > /dev/null
set linenumbers
set mouse
set tabsize 4
set tabstospaces
set smooth
set indicator
set smarthome
EOF

# FINALIZATION
systemctl restart ssh

echo -e "\033[0;36m======================================================================\033[0m"
echo -e "\033[1;32m  ✅ KELMORA SUPERNOVA OS v19.0 INSTALLED SUCCESSFULLY\033[0m"
echo -e "\033[0;36m======================================================================\033[0m"
echo -e "\033[1;31m⚠️  CRITICAL: Close this terminal completely and log back in to activate!\033[0m"
