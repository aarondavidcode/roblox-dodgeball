#!/usr/bin/env bash
# Idempotent Cloud Agent install: Luau linter (Selene) + formatter (StyLua).
set -euo pipefail

if ! command -v git >/dev/null 2>&1; then
  echo "error: git is required but not installed" >&2
  exit 1
fi

INSTALL_DIR="${HOME}/.local/bin"
mkdir -p "$INSTALL_DIR"

SELENE_VER="0.32.0"
STYLUA_VER="2.6.0"

if [[ -x "${INSTALL_DIR}/selene" && -x "${INSTALL_DIR}/stylua" ]]; then
  PATH="${INSTALL_DIR}:${PATH}"
  if selene --version >/dev/null 2>&1 && stylua --version >/dev/null 2>&1; then
    selene --version
    stylua --version
    echo "Luau tooling ready (already installed)."
    exit 0
  fi
fi

if ! command -v unzip >/dev/null 2>&1; then
  if command -v apt-get >/dev/null 2>&1; then
    sudo apt-get update -qq
    sudo apt-get install -y -qq unzip
  else
    echo "error: unzip is required to install Selene and StyLua" >&2
    exit 1
  fi
fi

ARCH="$(uname -m)"
case "$ARCH" in
  x86_64) STYLUA_ASSET="stylua-linux-x86_64.zip" ;;
  aarch64) STYLUA_ASSET="stylua-linux-aarch64.zip" ;;
  *)
    echo "error: unsupported architecture: ${ARCH}" >&2
    exit 1
    ;;
esac

TMPDIR="$(mktemp -d)"
trap 'rm -rf "${TMPDIR}"' EXIT

curl -fsSL -o "${TMPDIR}/selene.zip" \
  "https://github.com/Kampfkarren/selene/releases/download/${SELENE_VER}/selene-${SELENE_VER}-linux.zip"
curl -fsSL -o "${TMPDIR}/stylua.zip" \
  "https://github.com/JohnnyMorganz/StyLua/releases/download/v${STYLUA_VER}/${STYLUA_ASSET}"

unzip -q -o "${TMPDIR}/selene.zip" -d "${TMPDIR}/selene"
unzip -q -o "${TMPDIR}/stylua.zip" -d "${TMPDIR}/stylua"

install -m 0755 "${TMPDIR}/selene/selene" "${INSTALL_DIR}/selene"
install -m 0755 "${TMPDIR}/stylua/stylua" "${INSTALL_DIR}/stylua"

PATH="${INSTALL_DIR}:${PATH}"
selene --version
stylua --version
echo "Luau tooling ready."