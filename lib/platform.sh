#!/usr/bin/env bash
# Local VPS inspection and the explicit Kelmora support policy.

PLATFORM_ID="unknown"
PLATFORM_NAME="Unknown Linux"
PLATFORM_VERSION="unknown"
PLATFORM_ARCH="unknown"
PLATFORM_VIRTUALISATION="unknown"
PLATFORM_MEMORY_MB="unknown"
PLATFORM_DISK_GB="unknown"
PLATFORM_INTERFACE="unknown"
PLATFORM_SYSTEMD="no"
PLATFORM_APT="no"
PLATFORM_BBR="no"
PLATFORM_SUPPORTED="no"
PLATFORM_SUPPORT_REASON="Platform detection has not run."

platform_version_at_least() {
    local actual=$1 required=$2
    [[ -n ${actual} && -n ${required} ]] || return 1
    [[ $(printf '%s\n%s\n' "${required}" "${actual}" | sort -V | head -n 1) == "${required}" ]]
}

platform_arch_normalise() {
    case "$1" in
        x86_64|amd64) printf 'amd64' ;;
        aarch64|arm64) printf 'arm64' ;;
        *) printf '%s' "$1" ;;
    esac
}

platform_support_check() {
    PLATFORM_SUPPORTED="no"
    PLATFORM_SUPPORT_REASON=""
    if [[ ${PLATFORM_APT} != "yes" ]]; then
        PLATFORM_SUPPORT_REASON="APT is required."
    elif [[ ${PLATFORM_ARCH} != "amd64" && ${PLATFORM_ARCH} != "arm64" ]]; then
        PLATFORM_SUPPORT_REASON="Only amd64 and arm64 are currently supported."
    elif [[ ${PLATFORM_ID} == "ubuntu" ]] && platform_version_at_least "${PLATFORM_VERSION}" "22.04"; then
        PLATFORM_SUPPORTED="yes"
        PLATFORM_SUPPORT_REASON="Ubuntu ${PLATFORM_VERSION} on ${PLATFORM_ARCH} is supported."
    elif [[ ${PLATFORM_ID} == "debian" ]] && platform_version_at_least "${PLATFORM_VERSION}" "12"; then
        PLATFORM_SUPPORTED="yes"
        PLATFORM_SUPPORT_REASON="Debian ${PLATFORM_VERSION} on ${PLATFORM_ARCH} is supported."
    elif [[ ${PLATFORM_ID} == "ubuntu" || ${PLATFORM_ID} == "debian" ]]; then
        PLATFORM_SUPPORT_REASON="${PLATFORM_NAME} is below Kelmora's supported release policy."
    else
        PLATFORM_SUPPORT_REASON="${PLATFORM_NAME} is not in Kelmora's supported OS policy."
    fi
}

platform_detect() {
    local os_release=${KELMORA_OS_RELEASE_PATH:-/etc/os-release}
    if [[ -r ${os_release} ]]; then
        # os-release is an OS-owned data file. Its values are only used as data.
        # shellcheck disable=SC1090
        . "${os_release}"
        PLATFORM_ID=${ID:-unknown}
        PLATFORM_NAME=${PRETTY_NAME:-${NAME:-Unknown Linux}}
        PLATFORM_VERSION=${VERSION_ID:-unknown}
    fi
    PLATFORM_ARCH=$(platform_arch_normalise "$(uname -m 2>/dev/null || printf unknown)")
    if kelmora_command_exists apt-get; then PLATFORM_APT="yes"; fi
    if kelmora_command_exists systemctl; then PLATFORM_SYSTEMD="yes"; fi

    if kelmora_command_exists systemd-detect-virt; then
        PLATFORM_VIRTUALISATION=$(systemd-detect-virt 2>/dev/null || printf 'none')
    elif [[ -f /.dockerenv ]]; then
        PLATFORM_VIRTUALISATION="docker"
    fi
    if kelmora_command_exists free; then
        PLATFORM_MEMORY_MB=$(free -m | awk '/^Mem:/ {print $2; exit}')
    fi
    if kelmora_command_exists df; then
        PLATFORM_DISK_GB=$(df -Pm / 2>/dev/null | awk 'NR==2 {printf "%.1f", $2 / 1024}')
    fi
    if kelmora_command_exists ip; then
        PLATFORM_INTERFACE=$(ip route show default 2>/dev/null | awk 'NR==1 {for (i=1; i<=NF; i++) if ($i == "dev") {print $(i + 1); exit}}')
        [[ -n ${PLATFORM_INTERFACE} ]] || PLATFORM_INTERFACE="unknown"
    fi
    if kelmora_command_exists sysctl && sysctl net.ipv4.tcp_available_congestion_control 2>/dev/null | grep -qw bbr; then
        PLATFORM_BBR="yes"
    fi
    platform_support_check
}

platform_require_supported() {
    [[ ${PLATFORM_SUPPORTED} == "yes" ]] || kelmora_die "Unsupported platform: ${PLATFORM_SUPPORT_REASON} No changes were made."
}

platform_render_report() {
    ui_header "Kelmora VPS Check" "Local inspection only — no network requests"
    ui_key_value "Operating system" "${PLATFORM_NAME}"
    ui_key_value "Architecture" "${PLATFORM_ARCH}"
    ui_key_value "Virtualisation" "${PLATFORM_VIRTUALISATION}"
    ui_key_value "Memory" "${PLATFORM_MEMORY_MB} MiB"
    ui_key_value "Root storage" "${PLATFORM_DISK_GB} GiB"
    ui_key_value "Default interface" "${PLATFORM_INTERFACE}"
    ui_key_value "Service manager" "${PLATFORM_SYSTEMD}"
    ui_key_value "Package manager" "${PLATFORM_APT}"
    ui_key_value "BBR available" "${PLATFORM_BBR}"
    printf '\n'
    if [[ ${PLATFORM_SUPPORTED} == "yes" ]]; then
        ui_success "Supported — ${PLATFORM_SUPPORT_REASON}"
    else
        ui_error "Not supported — ${PLATFORM_SUPPORT_REASON}"
    fi
}
