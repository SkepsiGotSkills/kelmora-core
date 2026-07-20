#!/usr/bin/env bash
# Kelmora's public bootstrap installer.
# It is intentionally small: fetch a Kelmora release, verify it, then run it.

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
    while (( $# > 0 )); do
        case "$1" in
            --release)
                shift
                [[ $# -gt 0 ]] || die "--release needs a tag."
                KELMORA_RELEASE=$1
                ;;
            --release=*) KELMORA_RELEASE=${1#*=} ;;
            --help|-h) usage; return 0 ;;
            *) die "Unknown option: $1" ;;
        esac
        shift
    done
    [[ ${EUID} -eq 0 ]] || die "Run with sudo."
    validate_release
    command -v tar >/dev/null 2>&1 || die "tar is required."
    command -v sha256sum >/dev/null 2>&1 || die "sha256sum is required."
    command -v awk >/dev/null 2>&1 || die "awk is required."
    command -v find >/dev/null 2>&1 || die "find is required."
    command -v install >/dev/null 2>&1 || die "install is required."
    command -v mktemp >/dev/null 2>&1 || die "mktemp is required."

    WORKDIR=$(mktemp -d -t kelmora-bootstrap.XXXXXX)
    local archive="${WORKDIR}/${ASSET_NAME}"
    local checksum="${WORKDIR}/${CHECKSUM_NAME}"
    local extract="${WORKDIR}/extract"
    note "Downloading Kelmora ${KELMORA_RELEASE} release metadata…"
    fetch "$(release_url "${CHECKSUM_NAME}")" "${checksum}"
    note "Downloading Kelmora ${KELMORA_RELEASE} installer…"
    fetch "$(release_url "${ASSET_NAME}")" "${archive}"
    verify_archive "${archive}" "${checksum}"
    validate_archive_paths "${archive}"
    note "Verified release checksum. Starting Kelmora onboarding…"
    install -d -m 0700 "${extract}"
    tar --no-same-owner --no-same-permissions -xzf "${archive}" -C "${extract}"

    local -a entries=()
    mapfile -t entries < <(find "${extract}" -type f -name kelmora-installer -print)
    (( ${#entries[@]} == 1 )) || die "The release archive does not contain one Kelmora installer entry point."
    local entry=${entries[0]} root
    root=$(dirname -- "${entry}")
    [[ -r "${root}/lib/common.sh" && -r "${root}/lib/platform.sh" ]] || die "The release archive is incomplete."
    exec bash "${entry}"
}

main "$@"
