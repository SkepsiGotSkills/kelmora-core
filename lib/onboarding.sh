#!/usr/bin/env bash
# First-run onboarding state machine. It collects choices before installation.

onboarding_profile_default_index() {
    case "${KELMORA_PROFILE}" in
        core) printf '0' ;;
        hosting) printf '1' ;;
        developer) printf '2' ;;
        *) printf '0' ;;
    esac
}

onboarding_choose_profile() {
    local default
    default=$(onboarding_profile_default_index)
    ui_step "2 / 4" "Choose your foundation" "You can add specialised workloads later as explicit modules."
    ui_choose "What will this VPS primarily be used for?" "${default}" \
        "Core console — diagnostics, navigation, and daily server operations" \
        "Hosting essentials — core console plus UFW and Fail2Ban packages" \
        "Developer console — core console plus local build and ShellCheck tools"
    case "${UI_SELECTION}" in
        0) KELMORA_PROFILE="core" ;;
        1) KELMORA_PROFILE="hosting" ;;
        2) KELMORA_PROFILE="developer" ;;
    esac
    ui_success "Selected profile: ${KELMORA_PROFILE}"
}

onboarding_choose_network() {
    ui_step "3 / 4" "Network preference" "Kelmora never forces kernel tuning."
    if [[ ${PLATFORM_BBR} != "yes" ]]; then
        KELMORA_TUNE_NETWORK=0
        ui_warning "BBR is not advertised by this kernel, so network tuning is unavailable."
        return 0
    fi

    local default=0
    (( KELMORA_TUNE_NETWORK )) && default=1
    ui_choose "Choose a congestion-control policy" "${default}" \
        "Keep the server's existing network configuration" \
        "Apply BBR — verified available on this kernel"
    if (( UI_SELECTION == 1 )); then
        KELMORA_TUNE_NETWORK=1
        ui_success "BBR will be checked once more immediately before it is applied."
    else
        KELMORA_TUNE_NETWORK=0
        ui_success "Existing network configuration will be preserved."
    fi
}

onboarding_run() {
    ui_header "Welcome to Kelmora" "A calm, explicit setup for your VPS"
    printf '%b  Kelmora will inspect this server locally, build a plan, and ask\n' "${UI_WHITE}"
    printf '%b  for final confirmation before changing anything.%b\n\n' "${UI_WHITE}" "${UI_RESET}"
    if kelmora_is_installed; then
        ui_warning "An existing Kelmora installation was found. This flow safely repairs/reconciles its owned files."
    fi

    ui_step "1 / 4" "Check this VPS" "Compatibility is assessed before package or file operations."
    platform_render_report
    platform_require_supported
    ui_wait_for_key

    ui_header "Kelmora Onboarding" "Personalise the foundation"
    onboarding_choose_profile
    onboarding_choose_network

    ui_step "4 / 4" "Review your plan" "Nothing has been changed yet."
    plan_build "${KELMORA_PROFILE}"
    plan_render
    install_apply_plan
}
