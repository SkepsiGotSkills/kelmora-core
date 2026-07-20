#!/usr/bin/env bash
# Create the two GitHub Release assets consumed by ../install.sh.

set -Eeuo pipefail
IFS=$'\n\t'
umask 022

ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd -P)"
VERSION=""
OUTPUT_DIR="${ROOT}/dist"
WORKDIR=""

die() { printf 'Kelmora release: %s\n' "$*" >&2; exit 1; }
cleanup() { [[ -n ${WORKDIR} && -d ${WORKDIR} ]] && rm -rf -- "${WORKDIR}"; }
trap cleanup EXIT

usage() {
    cat <<'EOF'
Usage: bash scripts/package-release.sh --version v0.1.0 [--output DIRECTORY]

Creates:
  kelmora-installer.tar.gz
  kelmora-installer.tar.gz.sha256

Upload both files unchanged to the matching GitHub Release. The public
bootstrap uses those exact asset names for both latest and version-pinned installs.
EOF
}

main() {
    while (( $# > 0 )); do
        case "$1" in
            --version)
                shift
                [[ $# -gt 0 ]] || die "--version needs a tag such as v0.1.0."
                VERSION=$1
                ;;
            --version=*) VERSION=${1#*=} ;;
            --output)
                shift
                [[ $# -gt 0 ]] || die "--output needs a directory."
                OUTPUT_DIR=$1
                ;;
            --output=*) OUTPUT_DIR=${1#*=} ;;
            --help|-h) usage; return 0 ;;
            *) die "Unknown option: $1" ;;
        esac
        shift
    done
    [[ ${VERSION} =~ ^v[0-9][A-Za-z0-9._-]*$ ]] || die "Use a version tag such as v0.1.0."
    command -v tar >/dev/null 2>&1 || die "tar is required."
    command -v sha256sum >/dev/null 2>&1 || die "sha256sum is required."
    [[ -f "${ROOT}/kelmora-installer" && -f "${ROOT}/install.sh" ]] || die "Run this from a complete Kelmora source tree."

    WORKDIR=$(mktemp -d -t kelmora-release.XXXXXX)
    local stage="${WORKDIR}/kelmora-installer"
    install -d -m 0755 "${stage}/lib" "${stage}/tests"
    install -m 0755 "${ROOT}/kelmora-installer" "${stage}/kelmora-installer"
    install -m 0755 "${ROOT}/install.sh" "${stage}/install.sh"
    install -m 0644 "${ROOT}/README.md" "${stage}/README.md"
    local file
    for file in "${ROOT}"/lib/*.sh; do install -m 0644 "${file}" "${stage}/lib/${file##*/}"; done
    for file in "${ROOT}"/tests/*.sh; do install -m 0755 "${file}" "${stage}/tests/${file##*/}"; done

    install -d -m 0755 "${OUTPUT_DIR}"
    local archive="${OUTPUT_DIR}/kelmora-installer.tar.gz"
    tar -C "${WORKDIR}" -czf "${archive}" kelmora-installer
    (cd "${OUTPUT_DIR}" && sha256sum kelmora-installer.tar.gz >kelmora-installer.tar.gz.sha256)
    printf 'Release assets for %s:\n  %s\n  %s\n' "${VERSION}" "${archive}" "${archive}.sha256"
}

main "$@"
