#!/usr/bin/env bash
# Shared runtime safety, logging, and option parsing.

readonly KELMORA_MARKER_FILE="${KELMORA_STATE_DIR}/installed-version"
readonly KELMORA_MANIFEST_FILE="${KELMORA_STATE_DIR}/manifest"
readonly KELMORA_PROFILE_PATH="/etc/profile.d/kelmora.sh"
readonly KELMORA_MOTD_PATH="/etc/update-motd.d/99-kelmora"
readonly KELMORA_SYSCTL_PATH="/etc/sysctl.d/99-kelmora.conf"

KELMORA_ASSUME_YES=0
KELMORA_DRY_RUN=0
KELMORA_NO_COLOR=0
KELMORA_TUNE_NETWORK=0
KELMORA_PROFILE="core"
KELMORA_TRANSACTION_DIR=""

kelmora_die() {
    printf 'Kelmora: %s\n' "$*" >&2
    exit 1
}

kelmora_note() { printf '%s\n' "$*"; }

kelmora_require_root() {
    [[ ${EUID} -eq 0 ]] || kelmora_die "This operation needs root. Run: sudo bash kelmora-installer <command>"
}

kelmora_command_exists() { command -v "$1" >/dev/null 2>&1; }

kelmora_is_interactive() { [[ -t 0 && -t 1 ]]; }

kelmora_is_installed() { [[ -f "${KELMORA_MARKER_FILE}" ]]; }

kelmora_parse_options() {
    while (( $# > 0 )); do
        case "$1" in
            --dry-run) KELMORA_DRY_RUN=1 ;;
            --yes|-y) KELMORA_ASSUME_YES=1 ;;
            --no-color) KELMORA_NO_COLOR=1 ;;
            --tune-network) KELMORA_TUNE_NETWORK=1 ;;
            --profile)
                shift
                [[ $# -gt 0 ]] || kelmora_die "--profile needs a value."
                KELMORA_PROFILE=$1
                ;;
            --profile=*) KELMORA_PROFILE=${1#*=} ;;
            *) kelmora_die "Unknown option: $1" ;;
        esac
        shift
    done
}

kelmora_confirm() {
    local prompt=${1:-Continue?}
    if (( KELMORA_ASSUME_YES )); then
        return 0
    fi
    kelmora_is_interactive || kelmora_die "Use --yes for non-interactive execution."
    local response
    read -r -p "${prompt} [y/N] " response
    [[ ${response} =~ ^[Yy]([Ee][Ss])?$ ]]
}

kelmora_write_file() {
    local path=$1 mode=$2 parent
    parent=$(dirname -- "${path}")
    if (( KELMORA_DRY_RUN )); then
        kelmora_note "[dry-run] would write ${path}"
        cat >/dev/null
        return 0
    fi
    install -d -m 0755 "${parent}"
    install -m "${mode}" /dev/stdin "${path}"
}

kelmora_safe_remove() {
    local target
    for target in "$@"; do
        case "${target}" in
            /usr/local/bin/kelmora|/etc/profile.d/kelmora.sh|/etc/update-motd.d/99-kelmora|/etc/sysctl.d/99-kelmora.conf|/etc/kelmora|/usr/local/lib/kelmora|/var/lib/kelmora) ;;
            *) kelmora_die "Refusing a non-Kelmora remove target: ${target}" ;;
        esac
        if (( KELMORA_DRY_RUN )); then
            kelmora_note "[dry-run] would remove ${target}"
        else
            rm -rf -- "${target}"
        fi
    done
}

kelmora_begin_transaction() {
    local stamp
    stamp=$(date -u +%Y%m%dT%H%M%SZ)
    KELMORA_TRANSACTION_DIR="${KELMORA_STATE_DIR}/transactions/${stamp}-$$"
    if (( KELMORA_DRY_RUN )); then
        kelmora_note "[dry-run] would create transaction ${KELMORA_TRANSACTION_DIR}"
        return 0
    fi
    install -d -m 0700 "${KELMORA_TRANSACTION_DIR}"
    printf 'version=%s\nstarted_at=%s\n' "${KELMORA_VERSION}" "${stamp}" >"${KELMORA_TRANSACTION_DIR}/transaction"
}

kelmora_finish_transaction() {
    [[ -n "${KELMORA_TRANSACTION_DIR}" ]] || return 0
    if (( ! KELMORA_DRY_RUN )); then
        printf 'completed_at=%s\n' "$(date -u +%Y%m%dT%H%M%SZ)" >>"${KELMORA_TRANSACTION_DIR}/transaction"
    fi
}

kelmora_apt() {
    DEBIAN_FRONTEND=noninteractive apt-get "$@"
}
