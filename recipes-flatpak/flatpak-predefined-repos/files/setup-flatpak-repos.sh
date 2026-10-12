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
# flatpak-predefined-repos recipe, so no network fetch is required and a
# failed download can never leave the remote unverified.
PENSHUB_GPG_KEY="/usr/share/flatpak-repos/penshub.gpg"
# Shared runtime the PENSHub apps are built against.
GNOME_PLATFORM="org.gnome.Platform//45"

echo "[flatpak-repos] Configuring Flatpak remote repositories..."

# ── PENSHub (PENS AGL App Store repository) ──────────────────
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

# PENSHub's summary signing is not configured upstream, so summary checks are
# disabled for that remote only. Per-commit GPG verification (the part that
# actually protects the payloads) stays ON -- no --no-gpg-verify anywhere.
if flatpak remote-list --system | grep -q "penshub"; then
    ostree config --repo=/var/lib/flatpak/repo \
        set 'remote "penshub".gpg-verify-summary' 'false' || \
        echo "[flatpak-repos] WARN: could not disable penshub summary verification"
fi

# ── Flathub (public community repository) ────────────────────
if ! flatpak remote-list --system | grep -q "flathub"; then
    echo "[flatpak-repos] Adding Flathub remote..."
    flatpak remote-add --system --if-not-exists \
        flathub "${FLATHUB_URL}"
    echo "[flatpak-repos] Flathub remote added."
else
    echo "[flatpak-repos] Flathub remote already exists, skipping."
fi

# ── Install shared runtime (org.gnome.Platform) ──────────────
# The PENSHub apps are built against GNOME 44/45; the runtime must match the
# flatpak they were built with, otherwise they refuse to start.
if ! flatpak info --system "${GNOME_PLATFORM}" >/dev/null 2>&1; then
    echo "[flatpak-repos] Installing ${GNOME_PLATFORM} runtime from Flathub..."
    flatpak install --system --noninteractive flathub \
        "${GNOME_PLATFORM}" || \
        echo "[flatpak-repos] WARN: Runtime install deferred (network may be unavailable)"
else
    echo "[flatpak-repos] ${GNOME_PLATFORM} already installed."
fi

echo "[flatpak-repos] Repository setup complete."
echo "[flatpak-repos] Configured remotes:"
flatpak remote-list --system --show-details
