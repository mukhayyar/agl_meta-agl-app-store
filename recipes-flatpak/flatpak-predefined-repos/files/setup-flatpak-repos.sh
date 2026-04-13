#!/bin/sh
# ============================================================
# setup-flatpak-repos.sh
# Registers PENSHub and Flathub as system-wide Flatpak remotes
# with proper GPG verification.
# Runs once on first boot via systemd oneshot service.
# ============================================================

set -e

PENSHUB_URL="https://repo.agl-store.cyou"
PENSHUB_GPG_URL="${PENSHUB_URL}/public.gpg"
FLATHUB_URL="https://dl.flathub.org/repo"
GPG_KEYRING="/var/lib/flatpak/penshub-keyring.gpg"

echo "[flatpak-repos] Configuring Flatpak remote repositories..."

# ── PENSHub (PENS AGL App Store repository) ──────────────────
# The GPG public key is served by the OSTree repo at /public.gpg
# We fetch it and pass it to flatpak remote-add for verification
if ! flatpak remote-list --system | grep -q "penshub"; then
    echo "[flatpak-repos] Fetching PENSHub GPG public key from ${PENSHUB_GPG_URL}..."
    GPG_FETCHED=0
    if command -v wget >/dev/null 2>&1; then
        wget -q -O "${GPG_KEYRING}" "${PENSHUB_GPG_URL}" && GPG_FETCHED=1
    elif command -v curl >/dev/null 2>&1; then
        curl -sfL -o "${GPG_KEYRING}" "${PENSHUB_GPG_URL}" && GPG_FETCHED=1
    fi

    if [ "${GPG_FETCHED}" = "1" ] && [ -s "${GPG_KEYRING}" ]; then
        echo "[flatpak-repos] GPG key fetched. Adding PENSHub remote with GPG verification..."
        flatpak remote-add --system --if-not-exists \
            --gpg-import="${GPG_KEYRING}" \
            penshub "${PENSHUB_URL}"
        echo "[flatpak-repos] PENSHub remote added with GPG verification enabled."
    else
        echo "[flatpak-repos] ERROR: Could not fetch GPG key. Skipping PENSHub."
        echo "[flatpak-repos] Will retry on next boot."
        rm -f /var/lib/flatpak/.repos-configured
    fi
else
    echo "[flatpak-repos] PENSHub remote already exists, skipping."
fi

# ── Flathub (public community repository) ────────────────────
# Flathub's GPG key is bundled with flatpak or fetched automatically
if ! flatpak remote-list --system | grep -q "flathub"; then
    echo "[flatpak-repos] Adding Flathub remote..."
    flatpak remote-add --system --if-not-exists \
        flathub "${FLATHUB_URL}"
    echo "[flatpak-repos] Flathub remote added."
else
    echo "[flatpak-repos] Flathub remote already exists, skipping."
fi

# ── Install shared runtime (org.gnome.Platform) ──────────────
# Required by PENSHub apps built against GNOME 46
if ! flatpak info --system org.gnome.Platform//46 >/dev/null 2>&1; then
    echo "[flatpak-repos] Installing org.gnome.Platform//46 runtime from Flathub..."
    flatpak install --system --noninteractive flathub \
        org.gnome.Platform//46 || \
        echo "[flatpak-repos] WARN: Runtime install deferred (network may be unavailable)"
else
    echo "[flatpak-repos] org.gnome.Platform//46 already installed."
fi

echo "[flatpak-repos] Repository setup complete."
echo "[flatpak-repos] Configured remotes:"
flatpak remote-list --system --show-details
