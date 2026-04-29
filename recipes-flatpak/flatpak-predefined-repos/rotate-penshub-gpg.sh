#!/bin/sh
# ============================================================
# rotate-penshub-gpg.sh
#
# Refreshes the bundled PENSHub GPG public key shipped by the
# flatpak-predefined-repos recipe.
#
# Run this on a developer machine (NOT on a target) whenever the
# PENSHub signing key is rotated upstream. The new key is fetched
# from the live repo, validated, and written into files/ so the
# next image build picks it up.
#
# Usage:
#   ./rotate-penshub-gpg.sh                # fetch from default URL
#   ./rotate-penshub-gpg.sh <url>          # fetch from a custom URL
#   PENSHUB_GPG_URL=<url> ./rotate-penshub-gpg.sh
# ============================================================

set -eu

DEFAULT_URL="https://repo.agl-store.cyou/public.gpg"
URL="${1:-${PENSHUB_GPG_URL:-$DEFAULT_URL}}"

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
TARGET="${SCRIPT_DIR}/files/penshub-public.gpg"
TMP="$(mktemp)"
trap 'rm -f "${TMP}"' EXIT

echo "[rotate-gpg] Fetching key from: ${URL}"
if command -v curl >/dev/null 2>&1; then
    curl -fsSL -o "${TMP}" "${URL}"
elif command -v wget >/dev/null 2>&1; then
    wget -q -O "${TMP}" "${URL}"
else
    echo "[rotate-gpg] ERROR: need curl or wget on PATH" >&2
    exit 1
fi

if [ ! -s "${TMP}" ]; then
    echo "[rotate-gpg] ERROR: downloaded key is empty" >&2
    exit 1
fi

# Sanity-check: file must look like a PGP public key block.
if command -v file >/dev/null 2>&1; then
    DESC="$(file -b "${TMP}")"
    case "${DESC}" in
        *"PGP public key"*|*"OpenPGP Public Key"*) ;;
        *)
            echo "[rotate-gpg] ERROR: downloaded file is not a PGP public key" >&2
            echo "[rotate-gpg]        file(1) reports: ${DESC}" >&2
            exit 1
            ;;
    esac
fi

# Show the fingerprint so the developer can verify out-of-band before
# committing — this is the whole point of pinning the key.
if command -v gpg >/dev/null 2>&1; then
    echo "[rotate-gpg] New key details:"
    gpg --show-keys --with-fingerprint --with-subkey-fingerprint "${TMP}" 2>/dev/null \
        | sed 's/^/    /'
    if [ -s "${TARGET}" ]; then
        echo "[rotate-gpg] Currently bundled key details:"
        gpg --show-keys --with-fingerprint --with-subkey-fingerprint "${TARGET}" 2>/dev/null \
            | sed 's/^/    /'
    fi
else
    echo "[rotate-gpg] (install gpg to see fingerprints)"
fi

if [ -s "${TARGET}" ] && cmp -s "${TMP}" "${TARGET}"; then
    echo "[rotate-gpg] Bundled key already matches upstream. Nothing to do."
    exit 0
fi

mkdir -p "$(dirname "${TARGET}")"
mv "${TMP}" "${TARGET}"
trap - EXIT

echo "[rotate-gpg] Updated: ${TARGET}"
echo "[rotate-gpg] Verify the fingerprint above against a trusted source,"
echo "[rotate-gpg] then commit the change and rebuild the image:"
echo "[rotate-gpg]     git add $(realpath --relative-to="${SCRIPT_DIR}/../.." "${TARGET}")"
echo "[rotate-gpg]     git commit -m 'rotate penshub gpg key'"
