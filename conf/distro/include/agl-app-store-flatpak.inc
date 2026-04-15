# ============================================================
# agl-app-store-flatpak.inc
# ============================================================
# Include this in local.conf to enable Flatpak support for the
# AGL App Store. Based on meta-flatpak/AGL branch guidelines.
#
# Prerequisites in bblayers.conf:
#   BBLAYERS += "${METADIR}/external/meta-openembedded/meta-gnome"
#
# Usage in local.conf:
#   include conf/distro/include/agl-app-store-flatpak.inc
# ============================================================

# Include flatpak in the image
IMAGE_INSTALL:append = " flatpak agl-app-store"

# Flatpak needs extra rootfs space for installed apps and runtimes
# Adds 4GB — adjust based on target storage capacity
IMAGE_ROOTFS_EXTRA_SPACE:append = " + 4000000"

# Ensure required distro features are enabled
# wayland  — AGL compositor uses Wayland
# seccomp  — Flatpak sandbox isolation
# x11      — needed so xorgproto / libX11 / xwayland can build. Without
#            it xwayland.bb is skipped and legacy GTK / wxWidgets /
#            Qt-X11 flatpak apps (Filezilla, GIMP, LibreOffice, ...)
#            can't render on AGL's Wayland-only compositor.
DISTRO_FEATURES:append = " wayland seccomp x11"

# ── XWayland bridge ─────────────────────────────────────────
# Build weston with its xwayland module compiled in. packagegroup-
# flatpak.bb already pulls in the xwayland recipe itself when `x11`
# is in DISTRO_FEATURES; this line makes sure the compositor knows
# how to spawn it. On its own this only makes the module available —
# the compositor still has to be told to load it at runtime, see the
# note at the bottom of this file.
PACKAGECONFIG:append:pn-weston = " xwayland"

# If you also ship AGL's own compositor (agl-compositor, based on
# libweston) uncomment the following. Harmless if the recipe is absent.
#PACKAGECONFIG:append:pn-agl-compositor = " xwayland"

# ────────────────────────────────────────────────────────────
# RUNTIME CONFIG — not handled by this include
# ────────────────────────────────────────────────────────────
# After rebuilding, tell the compositor to actually load xwayland. For
# stock weston, edit /etc/xdg/weston/weston.ini on the target (or
# author a weston-init bbappend that does this for you) and ensure:
#
#   [core]
#   modules=xwayland.so
#
# Verify on target:
#   echo $DISPLAY         # should print :0 once weston is up
#   pgrep -a Xwayland     # should show the Xwayland server
#
# flutter-auto launched as weston's child inherits $DISPLAY, and the
# agl-app-store launch code (FlatpakPlatform.launch) forwards DISPLAY
# into `flatpak run` automatically. No further Flutter-side changes.
