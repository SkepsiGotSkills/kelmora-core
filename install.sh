#!/usr/bin/env bash
# Kelmora's public bootstrap installer.
# It is intentionally small: fetch a Kelmora release, verify it, then run it.

set -Eeuo pipefail
IFS=$'\n\t'
umask 022

readonly DEFAULT_REPOSITORY="SkepsiGotSkills/kelmora-core"
readonly ASSET_NAME="kelmora-installer.tar.gz"
readonly CHECKSUM_NAME="kelmora-installer.tar.gz.sha256"

KELMORA_REPOSITORY="${KELMORA_REPOSITORY:-${DEFAULT_REPOSITORY}}"
KELMORA_RELEASE="latest"
WORKDIR=""

die() { printf 'Kelmora bootstrap: %s\n' "$*" >&2; exit 1; }
note() { printf 'Kelmora: %s\n' "$*"; }

cleanup() {
    [[ -n ${WORKDIR} && -d ${WORKDIR} ]] && rm -rf -- "${WORKDIR}"
}
trap cleanup EXIT

usage() {
    cat <<'EOF'
Kelmora bootstrap installer

Usage:
  curl -fsSL https://raw.githubusercontent.com/SkepsiGotSkills/kelmora-core/main/install.sh | sudo bash

Options:
  --release TAG  Install a specific Kelmora GitHub Release (for example v0.1.0)
  --help         Show this help

The bootstrap downloads Kelmora's release archive and its SHA-256 checksum,
verifies them locally, then starts the modular installer.
EOF
}

fetch() {
    local url=$1 output=$2
    if command -v curl >/dev/null 2>&1; then
        curl --fail --location --silent --show-error --retry 3 --connect-timeout 15 --output "${output}" "${url}"
    elif command -v wget >/dev/null 2>&1; then
        wget -q --tries=3 --timeout=15 -O "${output}" "${url}"
    else
        die "curl or wget is required to download the Kelmora release."
    fi
}

validate_release() {
    [[ ${KELMORA_RELEASE} == "latest" || ${KELMORA_RELEASE} =~ ^[A-Za-z0-9][A-Za-z0-9._-]*$ ]] || die "Invalid release tag: ${KELMORA_RELEASE}"
}

release_url() {
    local asset=$1 base
    if [[ ${KELMORA_RELEASE} == "latest" ]]; then
        base="https://github.com/${KELMORA_REPOSITORY}/releases/latest/download"
    else
        base="https://github.com/${KELMORA_REPOSITORY}/releases/download/${KELMORA_RELEASE}"
    fi
    printf '%s/%s' "${base}" "${asset}"
}

verify_archive() {
    local archive=$1 checksum=$2 expected actual
    expected=$(awk 'NF >= 1 && $1 ~ /^[A-Fa-f0-9]{64}$/ {print tolower($1); exit}' "${checksum}")
    [[ -n ${expected} ]] || die "The release checksum file is invalid."
    actual=$(sha256sum "${archive}" | awk '{print tolower($1)}')
    [[ ${actual} == "${expected}" ]] || die "Checksum mismatch. The archive was not executed."
}

validate_archive_paths() {
    local archive=$1
    tar -tzf "${archive}" | awk '
        /^\// { bad = 1 }
        /(^|\/)\.\.($|\/)/ { bad = 1 }
        END { exit bad }
    ' || die "Unsafe paths were found in the release archive."
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
