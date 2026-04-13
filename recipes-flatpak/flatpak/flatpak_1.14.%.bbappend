# ============================================================
# Flatpak bbappend for AGL App Store
# ============================================================
# Tunes the Flatpak build for AGL embedded environment:
#   - Disables systemd helper (AGL uses its own service management)
#   - Disables seccomp (not always available on embedded targets)
#   - Disables SELinux module
#   - Enables xauth for Wayland/X11 fallback
# ============================================================

# If the base flatpak recipe exists in meta-oe or meta-flatpak,
# this bbappend customises it for AGL embedded use.

PACKAGECONFIG:remove = "system-helper"
PACKAGECONFIG:append = " xauth"

EXTRA_OECONF += " \
    --disable-seccomp \
    --disable-selinux-module \
    --disable-system-helper \
    --with-system-install-dir=${FLATPAK_SYSTEM_DIR} \
    --disable-documentation \
    --disable-docbook-docs \
    --disable-gtk-doc-html \
"
