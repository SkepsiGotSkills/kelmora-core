#!/usr/bin/env bash
# Kelmora Bootstrap Installer
# Downloads the latest installer directly from GitHub.

set -Eeuo pipefail
IFS=$'\n\t'

readonly REPOSITORY="${KELMORA_REPOSITORY:-SkepsiGotSkills/kelmora-core}"
readonly BRANCH="${KELMORA_BRANCH:-main}"

WORKDIR=""

die() {
    printf 'Kelmora bootstrap: %s\n' "$*" >&2
    exit 1
}

note() {
    printf 'Kelmora: %s\n' "$*"
}

cleanup() {
    [[ -n "${WORKDIR}" && -d "${WORKDIR}" ]] && rm -rf "${WORKDIR}"
}
trap cleanup EXIT

fetch() {
    local url="$1"
    local output="$2"

    if command -v curl >/dev/null 2>&1; then
        curl --fail --location --silent --show-error \
            --retry 3 \
            --connect-timeout 15 \
            -o "$output" \
            "$url"
    elif command -v wget >/dev/null 2>&1; then
        wget -q -O "$output" "$url"
    else
        die "curl or wget is required."
    fi
}

usage() {
cat <<EOF
Kelmora Bootstrap Installer

Usage:

curl -fsSL https://get.kelmora.cloud | sudo bash

Optional environment variables:

KELMORA_REPOSITORY=SkepsiGotSkills/kelmora-core
KELMORA_BRANCH=main
EOF
}

main() {

    [[ ${EUID} -eq 0 ]] || die "Run using sudo."

    command -v bash >/dev/null || die "bash is required."

    WORKDIR="$(mktemp -d -t kelmora.XXXXXX)"

    note "Downloading latest Kelmora installer..."

    fetch \
        "https://raw.githubusercontent.com/${REPOSITORY}/${BRANCH}/kelmora-installer" \
        "${WORKDIR}/kelmora-installer"

    chmod +x "${WORKDIR}/kelmora-installer"

    install -d "${WORKDIR}/lib"

    note "Downloading required libraries..."

    fetch \
        "https://raw.githubusercontent.com/${REPOSITORY}/${BRANCH}/lib/common.sh" \
        "${WORKDIR}/lib/common.sh"

    fetch \
        "https://raw.githubusercontent.com/${REPOSITORY}/${BRANCH}/lib/platform.sh" \
        "${WORKDIR}/lib/platform.sh"

    chmod +x "${WORKDIR}/lib/"*.sh

    note "Starting Kelmora..."

    cd "${WORKDIR}"

    exec bash ./kelmora-installer
}

case "${1:-}" in
    -h|--help)
        usage
        exit 0
        ;;
esac

main