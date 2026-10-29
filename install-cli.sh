#!/usr/bin/env bash
set -euo pipefail

VERSION="${INPUT_VERSION:?version input is required}"
EXPECTED_SHA256="${INPUT_SHA256:?sha256 input is required}"
API_BASE="${LIMINAL_KEYS_API_BASE_URL:-https://api.liminalkeys.com}"

case "$(uname -s)" in
  Linux) os=linux ;;
  Darwin) os=osx ;;
  MINGW*|MSYS*|CYGWIN*) os=win ;;
  *)
    echo "::error::Unsupported runner OS for liminal-keys CLI"
    exit 1
    ;;
esac

arch="$(uname -m)"
case "${arch}" in
  x86_64|amd64) rid_arch=x64 ;;
  arm64|aarch64) rid_arch=arm64 ;;
  *)
    echo "::error::Unsupported runner architecture: ${arch}"
    exit 1
    ;;
esac

if [ "${os}" = win ]; then
  asset="liminal-keys-${os}-${rid_arch}.exe"
else
  asset="liminal-keys-${os}-${rid_arch}"
fi

tmpdir="$(mktemp -d)"
trap 'rm -rf "${tmpdir}"' EXIT

meta_json="${tmpdir}/cli-release.json"
code="$(curl -sS -w '%{http_code}' -o "${meta_json}" \
  -H "Accept: application/json" \
  "${API_BASE}/v1/public/cli/versions/${VERSION}" || true)"
if [[ "${code}" != "200" ]]; then
  echo "::error::Could not load CLI release metadata for ${VERSION} (HTTP ${code})."
  exit 1
fi

available="$(python3 -c 'import json,sys; print(json.load(open(sys.argv[1])).get("available", False))' "${meta_json}")"
if [[ "${available}" != "True" && "${available}" != "true" ]]; then
  echo "::error::CLI ${VERSION} is not published (available=false)."
  exit 1
fi

listed_sha="$(python3 - "${meta_json}" "${asset}" <<'PY'
import json, sys
data = json.load(open(sys.argv[1], encoding="utf-8"))
name = sys.argv[2]
for item in data.get("assets") or []:
    if item.get("name") == name:
        print(item.get("sha256", ""))
        break
PY
)"
if [[ -z "${listed_sha}" ]]; then
  echo "::error::${asset} not listed in public CLI metadata for ${VERSION}"
  exit 1
fi

code="$(curl -sS -L -w '%{http_code}' -o "${tmpdir}/${asset}" \
  "${API_BASE}/v1/public/cli/versions/${VERSION}/assets/${asset}/download" || true)"
if [[ "${code}" != "200" ]]; then
  echo "::error::CLI download failed (HTTP ${code})."
  exit 1
fi

if command -v sha256sum >/dev/null 2>&1; then
  actual="$(sha256sum "${tmpdir}/${asset}" | awk '{print $1}')"
else
  actual="$(shasum -a 256 "${tmpdir}/${asset}" | awk '{print $1}')"
fi

EXPECTED_SHA256="$(printf '%s' "${EXPECTED_SHA256}" | tr '[:upper:]' '[:lower:]')"
actual="$(printf '%s' "${actual}" | tr '[:upper:]' '[:lower:]')"
listed_sha="$(printf '%s' "${listed_sha}" | tr '[:upper:]' '[:lower:]')"

if [[ "${actual}" != "${EXPECTED_SHA256}" ]]; then
  echo "::error::SHA-256 mismatch for ${asset}: input sha256 does not match downloaded binary"
  exit 1
fi

if [[ "${actual}" != "${listed_sha}" ]]; then
  echo "::error::SHA-256 mismatch for ${asset}: public metadata does not match binary"
  exit 1
fi

install_dir="${RUNNER_TEMP:-/tmp}/liminal-keys/bin"
mkdir -p "${install_dir}"
if [ "${os}" = win ]; then
  install -m 0755 "${tmpdir}/${asset}" "${install_dir}/liminal-keys.exe"
else
  install -m 0755 "${tmpdir}/${asset}" "${install_dir}/liminal-keys"
fi
if [[ -n "${GITHUB_PATH:-}" ]]; then
  echo "${install_dir}" >> "${GITHUB_PATH}"
fi
