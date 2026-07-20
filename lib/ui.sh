#!/usr/bin/env bash
# Terminal visual system. It uses ANSI only when the terminal supports it.

UI_COLOR=0
UI_WIDTH=80
UI_TEAL=""; UI_WHITE=""; UI_GREEN=""; UI_YELLOW=""; UI_RED=""; UI_MUTED=""; UI_RESET=""

ui_init() {
    if (( ! KELMORA_NO_COLOR )) && [[ -t 1 && "${TERM:-dumb}" != "dumb" && -z "${NO_COLOR:-}" ]]; then
        UI_COLOR=1
        UI_TEAL=$'\033[38;2;16;150;138m'
        UI_WHITE=$'\033[1;37m'
        UI_GREEN=$'\033[1;32m'
        UI_YELLOW=$'\033[1;33m'
        UI_RED=$'\033[1;31m'
        UI_MUTED=$'\033[2m'
        UI_RESET=$'\033[0m'
    fi
    if kelmora_command_exists tput && [[ -t 1 ]]; then
        UI_WIDTH=$(tput cols 2>/dev/null || printf '80')
    fi
    [[ ${UI_WIDTH} =~ ^[0-9]+$ ]] || UI_WIDTH=80
    if (( UI_WIDTH < 48 )); then
        UI_WIDTH=48
    fi
}

ui_line() {
    local character=${1:--} length=$(( UI_WIDTH > 72 ? 72 : UI_WIDTH - 4 )) line
    printf -v line '%*s' "${length}" ''
    printf '%b%s%b\n' "${UI_TEAL}" "${line// /${character}}" "${UI_RESET}"
}

ui_header() {
    local title=$1 subtitle=${2:-}
    if kelmora_is_interactive; then clear 2>/dev/null || true; fi
    ui_line '='
    printf '%b  %s%b\n' "${UI_WHITE}" "${title}" "${UI_RESET}"
    [[ -n ${subtitle} ]] && printf '%b  %s%b\n' "${UI_MUTED}" "${subtitle}" "${UI_RESET}"
    ui_line '-'
}

ui_step() {
    local position=$1 title=$2 detail=${3:-}
    printf '\n%b  %s%b  %b%s%b\n' "${UI_TEAL}" "${position}" "${UI_RESET}" "${UI_WHITE}" "${title}" "${UI_RESET}"
    [[ -n ${detail} ]] && printf '%b  %s%b\n' "${UI_MUTED}" "${detail}" "${UI_RESET}"
}

ui_success() { printf '%b  ✓ %s%b\n' "${UI_GREEN}" "$*" "${UI_RESET}"; }
ui_warning() { printf '%b  ! %s%b\n' "${UI_YELLOW}" "$*" "${UI_RESET}"; }
ui_error()   { printf '%b  × %s%b\n' "${UI_RED}" "$*" "${UI_RESET}" >&2; }
ui_key_value() { printf '  %-18s %s\n' "$1" "$2"; }

# UI_SELECTION is set to the zero-based choice index.
ui_choose() {
    local title=$1 default=$2
    shift 2
    local -a choices=( "$@" )
    local index response
    printf '\n%b  %s%b\n' "${UI_WHITE}" "${title}" "${UI_RESET}"
    for index in "${!choices[@]}"; do
        if (( index == default )); then
            printf '%b  %d) %s  (recommended)%b\n' "${UI_TEAL}" "$((index + 1))" "${choices[index]}" "${UI_RESET}"
        else
            printf '  %d) %s\n' "$((index + 1))" "${choices[index]}"
        fi
    done
    if (( KELMORA_ASSUME_YES )); then
        UI_SELECTION=${default}
        return 0
    fi
    kelmora_is_interactive || kelmora_die "Interactive choice required; use --profile and --yes."
    while :; do
        read -r -p "Choose [$((${default} + 1))]: " response
        [[ -z ${response} ]] && { UI_SELECTION=${default}; return 0; }
        [[ ${response} =~ ^[0-9]+$ ]] && (( response >= 1 && response <= ${#choices[@]} )) && {
            UI_SELECTION=$((response - 1)); return 0;
        }
        ui_warning "Choose a number from 1 to ${#choices[@]}."
    done
}

ui_wait_for_key() {
    (( KELMORA_ASSUME_YES )) && return 0
    kelmora_is_interactive || return 0
    local ignored
    read -r -n 1 -s -p '  Press any key to continue…' ignored
    printf '\n'
}
