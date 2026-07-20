#!/usr/bin/env bash
# Run with: bash tests/test-platform.sh
set -Eeuo pipefail

ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd -P)"
KELMORA_VERSION="test"
KELMORA_STATE_DIR="/var/lib/kelmora"
KELMORA_CONFIG_DIR="/etc/kelmora"
KELMORA_BIN_PATH="/usr/local/bin/kelmora"

# shellcheck source=../lib/common.sh
source "${ROOT}/lib/common.sh"
# The policy tests do not render UI, but platform.sh references these helpers.
ui_header() { :; }
ui_key_value() { :; }
ui_success() { :; }
ui_error() { :; }
# shellcheck source=../lib/platform.sh
source "${ROOT}/lib/platform.sh"

pass=0
fail=0

assert_equals() {
    local expected=$1 actual=$2 label=$3
    if [[ ${expected} == "${actual}" ]]; then
        printf 'ok - %s\n' "${label}"
        pass=$((pass + 1))
    else
        printf 'not ok - %s (expected %s, got %s)\n' "${label}" "${expected}" "${actual}" >&2
        fail=$((fail + 1))
    fi
}

check_policy() {
    PLATFORM_ID=$1
    PLATFORM_VERSION=$2
    PLATFORM_ARCH=$3
    PLATFORM_APT=$4
    PLATFORM_NAME="${PLATFORM_ID} ${PLATFORM_VERSION}"
    platform_support_check
    assert_equals "$5" "${PLATFORM_SUPPORTED}" "$6"
}

assert_equals "amd64" "$(platform_arch_normalise x86_64)" "normalises x86_64"
assert_equals "arm64" "$(platform_arch_normalise aarch64)" "normalises aarch64"
platform_version_at_least "24.04" "22.04" && assert_equals yes yes "compares Ubuntu versions" || assert_equals yes no "compares Ubuntu versions"
platform_version_at_least "11" "12" && assert_equals no yes "rejects older Debian" || assert_equals no no "rejects older Debian"
check_policy ubuntu 22.04 amd64 yes yes "supports Ubuntu 22.04 amd64"
check_policy ubuntu 20.04 amd64 yes no "rejects Ubuntu 20.04"
check_policy debian 12 arm64 yes yes "supports Debian 12 arm64"
check_policy debian 11 amd64 yes no "rejects Debian 11"
check_policy debian 12 s390x yes no "rejects unsupported architecture"
check_policy ubuntu 24.04 amd64 no no "requires APT"

printf '%s passed; %s failed\n' "${pass}" "${fail}"
(( fail == 0 ))
