#!/usr/bin/env bash
set -euo pipefail

if [[ "${EUID}" -ne 0 ]]; then
  echo "Run as root: sudo ./install.sh" >&2
  exit 1
fi

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

install -d -m 755 /usr/local/bin
install -d -m 755 /usr/local/libexec
install -d -m 755 /usr/local/share/applications

install -m 755 "${PROJECT_ROOT}/bin/nas-mount-helper" /usr/local/bin/nas-mount-helper
install -m 755 "${PROJECT_ROOT}/libexec/nas-mount-helper-apply" /usr/local/libexec/nas-mount-helper-apply
install -m 755 "${PROJECT_ROOT}/libexec/nas-mount-helper-install-cifs-utils" /usr/local/libexec/nas-mount-helper-install-cifs-utils
install -m 644 "${PROJECT_ROOT}/share/nas-mount-helper.desktop" /usr/local/share/applications/nas-mount-helper.desktop

echo "Installed:"
echo "  /usr/local/bin/nas-mount-helper"
echo "  /usr/local/libexec/nas-mount-helper-apply"
echo "  /usr/local/libexec/nas-mount-helper-install-cifs-utils"
echo "  /usr/local/share/applications/nas-mount-helper.desktop"
