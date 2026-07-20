#!/usr/bin/env bash
# Profile definitions and a human-readable change plan.

declare -a PLAN_PACKAGES=()
declare -a PLAN_FILES=()
declare -a PLAN_NOTES=()
PLAN_PROFILE="core"
PLAN_RENDERED=0

plan_reset() {
    PLAN_PACKAGES=()
    PLAN_FILES=()
    PLAN_NOTES=()
    PLAN_RENDERED=0
}

plan_add_package() { PLAN_PACKAGES+=( "$1" ); }
plan_add_file() { PLAN_FILES+=( "$1" ); }
plan_add_note() { PLAN_NOTES+=( "$1" ); }

plan_add_core_packages() {
    local package
    local core=( ca-certificates curl git jq bat btop dnsutils fd-find fzf htop lnav mtr-tiny ncdu net-tools nethogs p7zip-full ranger ripgrep tar tree unzip )
    for package in "${core[@]}"; do plan_add_package "${package}"; done
}

plan_build() {
    local profile=${1:-core}
    plan_reset
    PLAN_PROFILE=${profile}
    case "${profile}" in
        core)
            plan_add_core_packages
            plan_add_note "A focused terminal workspace for operations and diagnostics."
            ;;
        hosting)
            plan_add_core_packages
            plan_add_package fail2ban
            plan_add_package ufw
            plan_add_note "Adds hosting-oriented security tools, but does not enable a firewall or alter SSH."
            ;;
        developer)
            plan_add_core_packages
            plan_add_package build-essential
            plan_add_package shellcheck
            plan_add_note "Adds local build and shell-quality tools from the configured APT repositories."
            ;;
        *) kelmora_die "Unknown profile '${profile}'. Choose core, hosting, or developer." ;;
    esac

    plan_add_file "/usr/local/bin/kelmora"
    plan_add_file "/etc/kelmora/env.sh"
    plan_add_file "/etc/profile.d/kelmora.sh"
    plan_add_file "/etc/update-motd.d/99-kelmora"
    plan_add_file "/usr/local/lib/kelmora/"
    plan_add_file "/var/lib/kelmora/"

    if (( KELMORA_TUNE_NETWORK )); then
        plan_add_file "/etc/sysctl.d/99-kelmora.conf"
        plan_add_note "Network tuning requested; BBR will be applied only after a second capability check."
    fi
    plan_add_note "Every package is resolved from the server's configured signed APT repositories."
    plan_add_note "Uninstall removes Kelmora-owned files and keeps APT packages to protect existing workflows."
}

plan_render_list() {
    local heading=$1
    shift
    printf '\n%b  %s%b\n' "${UI_WHITE}" "${heading}" "${UI_RESET}"
    local item
    for item in "$@"; do printf '    • %s\n' "${item}"; done
}

plan_render() {
    ui_header "Your Kelmora Plan" "Review before any system change"
    ui_key_value "Selected profile" "${PLAN_PROFILE}"
    ui_key_value "Package source" "configured signed APT repositories"
    ui_key_value "Network tuning" "$([[ ${KELMORA_TUNE_NETWORK} -eq 1 ]] && printf requested || printf disabled)"
    plan_render_list "Packages to install when available" "${PLAN_PACKAGES[@]}"
    plan_render_list "Kelmora-owned files" "${PLAN_FILES[@]}"
    plan_render_list "Notes" "${PLAN_NOTES[@]}"
    printf '\n'
    (( KELMORA_DRY_RUN )) && ui_warning "Dry-run enabled: no package or file change will be made."
    PLAN_RENDERED=1
}
