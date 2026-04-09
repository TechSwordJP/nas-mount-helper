#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'EOF' >&2
Usage: ./scripts/build-release-assets.sh <owner>/<repo> [output-dir]
EOF
  exit 1
}

if [[ "$#" -lt 1 || "$#" -gt 2 ]]; then
  usage
fi

REPO_SLUG="$1"
OUTPUT_DIR_INPUT="${2:-dist}"
PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SOURCE_ROOT="${PROJECT_ROOT}/src"

if [[ "${OUTPUT_DIR_INPUT}" = /* ]]; then
  OUTPUT_DIR="${OUTPUT_DIR_INPUT}"
else
  OUTPUT_DIR="${PROJECT_ROOT}/${OUTPUT_DIR_INPUT}"
fi

STAGING_DIR="$(mktemp -d)"
trap 'rm -rf "${STAGING_DIR}"' EXIT

ARCHIVE_NAME="payload.tar.gz"
BOOTSTRAP_NAME="setup.sh"
PACKAGE_ROOT="${STAGING_DIR}/nas-mount-helper"
BASE_URL="https://github.com/${REPO_SLUG}/releases/latest/download"

mkdir -p "${PACKAGE_ROOT}/bin" "${PACKAGE_ROOT}/libexec"

cp "${SOURCE_ROOT}/bin/nas-mount-helper" "${PACKAGE_ROOT}/bin/nas-mount-helper"
cp "${SOURCE_ROOT}/libexec/nas-mount-helper-apply" "${PACKAGE_ROOT}/libexec/nas-mount-helper-apply"
cp "${SOURCE_ROOT}/libexec/nas-mount-helper-install-cifs-utils" "${PACKAGE_ROOT}/libexec/nas-mount-helper-install-cifs-utils"

chmod 755 \
  "${PACKAGE_ROOT}/bin/nas-mount-helper" \
  "${PACKAGE_ROOT}/libexec/nas-mount-helper-apply" \
  "${PACKAGE_ROOT}/libexec/nas-mount-helper-install-cifs-utils"

mkdir -p "${OUTPUT_DIR}"
rm -f "${OUTPUT_DIR}/${ARCHIVE_NAME}" "${OUTPUT_DIR}/${BOOTSTRAP_NAME}"

export COPYFILE_DISABLE=1
tar -czf "${OUTPUT_DIR}/${ARCHIVE_NAME}" -C "${STAGING_DIR}" nas-mount-helper

cat >"${OUTPUT_DIR}/${BOOTSTRAP_NAME}" <<EOF
#!/bin/sh
set -eu

BASE_URL='${BASE_URL}'
ARCHIVE_URL="\${BASE_URL}/payload.tar.gz"

need_cmd() {
  if ! command -v "\$1" >/dev/null 2>&1; then
    echo "Required command missing: \$1" >&2
    exit 1
  fi
}

need_cmd curl
need_cmd tar
need_cmd mktemp

WORKDIR=\$(mktemp -d)
cleanup() {
  rm -rf "\${WORKDIR}"
}
trap cleanup EXIT INT TERM

echo "Downloading nas-mount-helper from \${ARCHIVE_URL}"
curl -fsSL "\${ARCHIVE_URL}" -o "\${WORKDIR}/payload.tar.gz"
tar -xzf "\${WORKDIR}/payload.tar.gz" -C "\${WORKDIR}"

if [ ! -x "\${WORKDIR}/nas-mount-helper/bin/nas-mount-helper" ]; then
  echo "nas-mount-helper executable not found in archive" >&2
  exit 1
fi

"\${WORKDIR}/nas-mount-helper/bin/nas-mount-helper"
EOF

chmod 755 "${OUTPUT_DIR}/${BOOTSTRAP_NAME}"

cat <<EOF
Built release artifacts:
  ${OUTPUT_DIR}/${ARCHIVE_NAME}
  ${OUTPUT_DIR}/${BOOTSTRAP_NAME}

Install command:
  curl -fsSL ${BASE_URL}/${BOOTSTRAP_NAME} | sh
EOF
