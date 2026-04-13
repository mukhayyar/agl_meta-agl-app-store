SUMMARY = "AGL PENS App Store"
DESCRIPTION = "Application Store for Automotive Grade Linux (AGL) — \
A Flutter-based embedded storefront that provides a unified interface \
for browsing, installing, and managing Flatpak applications from both \
PENSHub (private repository) and Flathub (public repository). \
Developed as part of the PENS Final Project (Proyek Akhir)."
AUTHOR = "Muhammad Tsaqif Mukhayyar <tsaqifmukhayyar@gmail.com>"
HOMEPAGE = "https://agl-store.cyou"
LICENSE = "MIT"
LIC_FILES_CHKSUM = "file://LICENSE;md5=d41d8cd98f00b204e9800998ecf8427e"
SECTION = "graphics"

PN = "agl-app-store"

SRC_URI = "gitsm://github.com/mukhayyar/agl-app-store.git;protocol=https;branch=main \
           file://agl-app-flutter@agl-app-store.service \
           "
SRCREV = "${AUTOREV}"

S = "${WORKDIR}/git"

inherit agl-app flutter-app

# ── Flutter configuration ────────────────────────────────────
PUBSPEC_APPNAME = "agl_app_store"
PUBSPEC_IGNORE_LOCKFILE = "1"
FLUTTER_APPLICATION_INSTALL_PREFIX = "/usr/share/flutter"
FLUTTER_BUILD_ARGS = "bundle -v"

# ── AGL application framework integration ────────────────────
# This registers the app with the AGL compositor so it appears
# in the IVI homescreen launcher
AGL_APP_TEMPLATE = "agl-app-flutter"
AGL_APP_ID = "agl_app_store"
AGL_APP_NAME = "AGL PENS App Store"

# ── Build dependencies ───────────────────────────────────────
# Native C++ plugin for Flatpak operations (Platform Channel)
DEPENDS += " \
    flatpak \
    glib-2.0 \
    gtk+3 \
"

# ── Runtime dependencies ─────────────────────────────────────
# Flatpak + OSTree runtime is required for install/uninstall/launch
# packagegroup-flatpak pulls in flatpak, ostree, and utilities
RDEPENDS:${PN} += " \
    packagegroup-flatpak \
    flatpak-predefined-repos \
"

# ── Install systemd service for AGL IVI display ──────────────
# This service file tells the AGL compositor to launch our Flutter
# app as a Wayland client, making it visible in the IVI homescreen
do_install:append() {
    install -D -m 0644 \
        ${WORKDIR}/agl-app-flutter@agl-app-store.service \
        ${D}${systemd_system_unitdir}/agl-app-flutter@agl-app-store.service
}

# Allow network access during build for pub dependencies
do_compile[network] = "1"
