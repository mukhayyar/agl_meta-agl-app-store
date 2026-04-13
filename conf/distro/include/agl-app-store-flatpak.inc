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
DISTRO_FEATURES:append = " wayland seccomp"
