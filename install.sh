#!/usr/bin/env bash
# Kelmora Bootstrap Installer
# Downloads the latest Kelmora repository from GitHub and starts the installer.

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

    [[ $EUID -eq 0 ]] || die "Run using sudo."

    command -v tar >/dev/null || die "tar is required."
    command -v mktemp >/dev/null || die "mktemp is required."

    WORKDIR="$(mktemp -d -t kelmora.XXXXXX)"

    local archive="${WORKDIR}/repo.tar.gz"

    note "Downloading latest Kelmora..."

    fetch \
        "https://github.com/${REPOSITORY}/archive/refs/heads/${BRANCH}.tar.gz" \
        "${archive}"

    note "Extracting..."

    tar -xzf "${archive}" -C "${WORKDIR}"

    local ROOT="${WORKDIR}/$(basename "${REPOSITORY}")-${BRANCH}"

    [[ -f "${ROOT}/kelmora-installer" ]] || die "kelmora-installer not found."

    chmod +x "${ROOT}/kelmora-installer"

    note "Starting Kelmora..."

    cd "${ROOT}"

    exec bash ./kelmora-installer
}

case "${1:-}" in
    -h|--help)
        usage
        exit 0
        ;;
esac

main