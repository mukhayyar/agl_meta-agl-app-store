#!/bin/sh
# ============================================================
# setup-flatpak-repos.sh
# Registers PENSHub and Flathub as system-wide Flatpak remotes
# with proper GPG verification.
# Runs once on first boot via systemd oneshot service.
# ============================================================

set -e

PENSHUB_URL="https://repo.agl-store.cyou"
# Use Flathub's .flatpakrepo file (NOT the bare /repo URL). The
# .flatpakrepo is a small INI file that carries the official GPG key
# inline, so `flatpak remote-add` registers flathub as GPG-verified.
# Passing the bare /repo URL here creates a non-verified remote, which
# makes every later `flatpak install` fail with:
#   "Can't pull from untrusted non-gpg verified remote"
FLATHUB_URL="https://dl.flathub.org/repo/flathub.flatpakrepo"
# PENSHub's GPG public key is baked into the image by the
# flatpak-predefined-repos recipe, so no network fetch is required.
PENSHUB_GPG_KEY="/usr/share/flatpak-predefined-repos/penshub-public.gpg"

echo "[flatpak-repos] Configuring Flatpak remote repositories..."

# ── PENSHub (PENS AGL App Store repository) ──────────────────
# Use the GPG public key shipped with the image. Fetching at runtime
# was unreliable: a failed download left penshub registered as a
# non-verified remote and every install of a penshub app failed.
if ! flatpak remote-list --system | grep -q "penshub"; then
    if [ -s "${PENSHUB_GPG_KEY}" ]; then
        echo "[flatpak-repos] Adding PENSHub remote with bundled GPG key..."
        flatpak remote-add --system --if-not-exists \
            --gpg-import="${PENSHUB_GPG_KEY}" \
            penshub "${PENSHUB_URL}"
        echo "[flatpak-repos] PENSHub remote added with GPG verification enabled."
    else
        echo "[flatpak-repos] ERROR: Bundled GPG key missing at ${PENSHUB_GPG_KEY}. Skipping PENSHub."
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
