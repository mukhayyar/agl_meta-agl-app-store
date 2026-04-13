#!/bin/sh
# ============================================================
# setup-flatpak-repos.sh
# Registers PENSHub and Flathub as system-wide Flatpak remotes
# Runs once on first boot via systemd oneshot service
# ============================================================

set -e

FLATPAK_SYSTEM_DIR="/var/lib/flatpak"
PENSHUB_URL="https://repo.agl-store.cyou"
FLATHUB_URL="https://dl.flathub.org/repo"

echo "[flatpak-repos] Configuring Flatpak remote repositories..."

# ── PENSHub (PENS AGL App Store private repository) ──────────
if ! flatpak remote-list --system | grep -q "penshub"; then
    echo "[flatpak-repos] Adding PENSHub remote: ${PENSHUB_URL}"
    flatpak remote-add --system --if-not-exists \
        --no-gpg-verify \
        penshub "${PENSHUB_URL}"
    echo "[flatpak-repos] PENSHub remote added successfully."
else
    echo "[flatpak-repos] PENSHub remote already exists, skipping."
fi

# ── Flathub (public community repository) ────────────────────
if ! flatpak remote-list --system | grep -q "flathub"; then
    echo "[flatpak-repos] Adding Flathub remote: ${FLATHUB_URL}"
    flatpak remote-add --system --if-not-exists \
        flathub "${FLATHUB_URL}"
    echo "[flatpak-repos] Flathub remote added successfully."
else
    echo "[flatpak-repos] Flathub remote already exists, skipping."
fi

# ── Install shared runtime (org.gnome.Platform) ──────────────
# The runtime is needed by PENSHub apps; install from Flathub
if ! flatpak info --system org.gnome.Platform//46 >/dev/null 2>&1; then
    echo "[flatpak-repos] Installing org.gnome.Platform//46 runtime..."
    flatpak install --system --noninteractive flathub \
        org.gnome.Platform//46 || echo "[flatpak-repos] WARN: Runtime install failed (may need network)"
else
    echo "[flatpak-repos] org.gnome.Platform//46 already installed."
fi

echo "[flatpak-repos] Repository setup complete."
echo "[flatpak-repos] Remotes configured:"
flatpak remote-list --system
