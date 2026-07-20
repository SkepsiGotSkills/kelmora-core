#!/usr/bin/env bash
# Deliberate installation, update, and uninstall operations.

install_resolve_packages() {
    local package
    for package in "$@"; do
        if apt-cache show "${package}" >/dev/null 2>&1; then
            printf '%s\n' "${package}"
        else
            ui_warning "Not available from this VPS's configured APT sources: ${package}" >&2
        fi
    done
}

install_apt_action() {
    local label=$1
    shift
    if (( KELMORA_DRY_RUN )); then
        ui_success "[dry-run] ${label}"
        return 0
    fi
    local log_file="${KELMORA_TRANSACTION_DIR}/apt-${label//[^a-zA-Z0-9]/-}.log"
    printf '%b  • %s%b\n' "${UI_TEAL}" "${label}" "${UI_RESET}"
    if kelmora_apt "$@" >"${log_file}" 2>&1; then
        ui_success "${label}"
    else
        ui_error "${label} failed. Last package-manager lines:"
        tail -n 20 "${log_file}" >&2 || true
        return 1
    fi
}

install_deploy_project() {
    local module
    if (( KELMORA_DRY_RUN )); then
        ui_success "[dry-run] deploy Kelmora installer modules"
        return 0
    fi
    install -d -m 0755 "${KELMORA_HOME}/lib"
    install -m 0755 "${KELMORA_ROOT}/kelmora-installer" "${KELMORA_HOME}/kelmora-installer"
    for module in "${KELMORA_ROOT}"/lib/*.sh; do
        [[ -f ${module} ]] || continue
        install -m 0644 "${module}" "${KELMORA_HOME}/lib/${module##*/}"
    done
    ui_success "Installed Kelmora's versioned local control plane"
}

install_deploy_environment() {
    kelmora_write_file "${KELMORA_CONFIG_DIR}/env.sh" 0644 <<'EOF'
# Managed by Kelmora. Interactive shell settings only.
export KELMORA_VERSION="28.0.0-alpha.1"
export HISTCONTROL="ignoreboth:erasedups"
export EDITOR="${EDITOR:-nano}"
export VISUAL="${VISUAL:-${EDITOR:-nano}}"
export FZF_DEFAULT_OPTS="${FZF_DEFAULT_OPTS:---height=70% --layout=reverse --border}"
command -v batcat >/dev/null 2>&1 && alias bat='batcat'
EOF
    kelmora_write_file "${KELMORA_PROFILE_PATH}" 0644 <<'EOF'
# Managed by Kelmora. Nothing in this file runs for non-interactive shells.
case $- in
    *i*) [ -r /etc/kelmora/env.sh ] && . /etc/kelmora/env.sh ;;
esac
EOF
    kelmora_write_file "${KELMORA_MOTD_PATH}" 0755 <<'EOF'
#!/usr/bin/env bash
set -u
C='\033[38;2;16;150;138m'; W='\033[1;37m'; R='\033[0m'
up=$(uptime -p 2>/dev/null | sed 's/^up //' || printf 'unavailable')
ip=$(hostname -I 2>/dev/null | awk '{print $1}' || true)
printf '%b%s%b\n' "$C" '------------------------------------------------------------' "$R"
printf '%b  Kelmora Cloud OS%b  uptime: %s' "$W" "$R" "$up"
[ -n "$ip" ] && printf '  address: %s' "$ip"
printf '\n%b  Type %bkelmora%b for your command center.\n' "$C" "$W" "$R"
printf '%b%s%b\n' "$C" '------------------------------------------------------------' "$R"
EOF
    ui_success "Installed shell experience and login dashboard"
}

install_deploy_command() {
    kelmora_write_file "${KELMORA_BIN_PATH}" 0755 <<EOF
#!/usr/bin/env bash
# Managed by Kelmora. The installed control plane is versioned and local.
exec "${KELMORA_HOME}/kelmora-installer" "\$@"
EOF
    ui_success "Installed the 'kelmora' command"
}

install_apply_network_tuning() {
    (( KELMORA_TUNE_NETWORK )) || return 0
    if [[ ${PLATFORM_BBR} != "yes" ]] || ! sysctl net.ipv4.tcp_available_congestion_control 2>/dev/null | grep -qw bbr; then
        ui_warning "BBR is no longer available; Kelmora preserved the existing network settings."
        return 0
    fi
    if (( ! KELMORA_DRY_RUN )); then
        install -d -m 0755 "${KELMORA_STATE_DIR}"
        {
            printf 'qdisc=%s\n' "$(sysctl -n net.core.default_qdisc 2>/dev/null || true)"
            printf 'congestion_control=%s\n' "$(sysctl -n net.ipv4.tcp_congestion_control 2>/dev/null || true)"
        } >"${KELMORA_STATE_DIR}/network-before-kelmora"
    fi
    kelmora_write_file "${KELMORA_SYSCTL_PATH}" 0644 <<'EOF'
# Managed by Kelmora. Removed by `kelmora uninstall`.
net.core.default_qdisc=fq
net.ipv4.tcp_congestion_control=bbr
EOF
    if (( KELMORA_DRY_RUN )); then
        ui_success "[dry-run] apply verified BBR tuning"
        return 0
    fi
    if sysctl -p "${KELMORA_SYSCTL_PATH}" >/dev/null; then
        ui_success "Applied verified BBR network tuning"
    else
        rm -f -- "${KELMORA_SYSCTL_PATH}"
        ui_warning "BBR could not be applied; Kelmora removed its tuning file."
    fi
}

install_write_state() {
    if (( KELMORA_DRY_RUN )); then
        ui_success "[dry-run] write Kelmora installation state"
        return 0
    fi
    install -d -m 0755 "${KELMORA_STATE_DIR}"
    printf '%s\n' "${KELMORA_VERSION}" >"${KELMORA_MARKER_FILE}"
    {
        printf 'version=%s\n' "${KELMORA_VERSION}"
        printf 'profile=%s\n' "${PLAN_PROFILE}"
        printf 'installed_at=%s\n' "$(date -u +%FT%TZ)"
        printf 'managed_paths=%s\n' "${KELMORA_BIN_PATH},${KELMORA_HOME},${KELMORA_CONFIG_DIR},${KELMORA_PROFILE_PATH},${KELMORA_MOTD_PATH},${KELMORA_SYSCTL_PATH},${KELMORA_STATE_DIR}"
    } >"${KELMORA_MANIFEST_FILE}"
    ui_success "Saved Kelmora installation manifest"
}

install_apply_plan() {
    platform_require_supported
    (( PLAN_RENDERED )) || plan_render
    if (( KELMORA_DRY_RUN )); then
        ui_success "Dry-run complete. No changes were made."
        return 0
    fi
    kelmora_confirm "Apply this Kelmora plan?" || { ui_warning "Installation cancelled. No changes were made."; return 0; }

    ui_header "Installing Kelmora" "Every action is recorded locally"
    kelmora_begin_transaction
    install_apt_action "Refresh package metadata" update
    local -a packages=()
    mapfile -t packages < <(install_resolve_packages "${PLAN_PACKAGES[@]}")
    (( ${#packages[@]} > 0 )) || kelmora_die "No planned packages are available from the configured APT repositories."
    install_apt_action "Install selected Kelmora tools" install -y --no-install-recommends "${packages[@]}"
    install_deploy_project
    install_deploy_environment
    install_deploy_command
    install_apply_network_tuning
    install_write_state
    kelmora_finish_transaction
    ui_header "Kelmora is ready" "Setup complete"
    ui_success "Open a new SSH session, then type: kelmora onboard"
    ui_note_after_install
}

ui_note_after_install() {
    printf '%b  Your exact plan and transaction are stored locally under %s.%b\n' "${UI_MUTED}" "${KELMORA_STATE_DIR}" "${UI_RESET}"
}

install_profile_from_manifest() {
    if [[ -r ${KELMORA_MANIFEST_FILE} ]]; then
        awk -F= '$1 == "profile" {print $2; exit}' "${KELMORA_MANIFEST_FILE}"
    else
        printf 'core'
    fi
}

install_update() {
    if ! kelmora_is_installed; then
        ui_warning "Kelmora is not installed. Building a new installation plan instead."
        plan_build "${KELMORA_PROFILE}"
        install_apply_plan
        return 0
    fi
    local saved_profile
    saved_profile=$(install_profile_from_manifest)
    plan_build "${saved_profile:-core}"
    plan_render
    (( KELMORA_DRY_RUN )) && { ui_success "Dry-run complete. No changes were made."; return 0; }
    kelmora_confirm "Upgrade APT packages and refresh Kelmora?" || { ui_warning "Update cancelled."; return 0; }

    ui_header "Updating Kelmora" "Package updates from configured signed APT sources"
    kelmora_begin_transaction
    install_apt_action "Refresh package metadata" update
    install_apt_action "Apply available package upgrades" upgrade -y
    local -a packages=()
    mapfile -t packages < <(install_resolve_packages "${PLAN_PACKAGES[@]}")
    (( ${#packages[@]} > 0 )) && install_apt_action "Repair selected Kelmora tools" install -y --no-install-recommends "${packages[@]}"
    install_deploy_project
    install_deploy_environment
    install_deploy_command
    install_write_state
    kelmora_finish_transaction
    ui_success "Kelmora and available APT packages are up to date."
}

install_restore_network() {
    local before="${KELMORA_STATE_DIR}/network-before-kelmora" qdisc cc
    [[ -r ${before} ]] || return 0
    qdisc=$(awk -F= '$1 == "qdisc" {print $2; exit}' "${before}")
    cc=$(awk -F= '$1 == "congestion_control" {print $2; exit}' "${before}")
    [[ -n ${qdisc} ]] && sysctl -w "net.core.default_qdisc=${qdisc}" >/dev/null 2>&1 || true
    [[ -n ${cc} ]] && sysctl -w "net.ipv4.tcp_congestion_control=${cc}" >/dev/null 2>&1 || true
}

install_uninstall() {
    ui_header "Remove Kelmora" "Kelmora packages will be retained"
    if ! kelmora_is_installed; then
        ui_warning "No Kelmora marker was found. Only known Kelmora paths will be considered."
    fi
    printf "%s\n" "  This removes Kelmora's command, configuration, local control plane,"
    printf '  login dashboard, optional tuning file, and state. It retains APT packages.\n\n'
    (( KELMORA_DRY_RUN )) && { ui_success "Dry-run complete. No changes were made."; return 0; }
    kelmora_confirm "Remove Kelmora-managed files?" || { ui_warning "Uninstall cancelled."; return 0; }
    install_restore_network
    kelmora_safe_remove "${KELMORA_BIN_PATH}" "${KELMORA_PROFILE_PATH}" "${KELMORA_MOTD_PATH}" "${KELMORA_SYSCTL_PATH}" "${KELMORA_CONFIG_DIR}" "${KELMORA_HOME}" "${KELMORA_STATE_DIR}"
    ui_success "Kelmora-managed files were removed. Installed APT packages remain available."
}
