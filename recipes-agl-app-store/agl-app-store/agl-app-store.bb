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
FLUTTER_APPLICATION_INSTALL_PREFIX = "/usr/share/flutter"
FLUTTER_BUILD_ARGS = "bundle -v"

# ── Lockfile workaround ──────────────────────────────────────
# meta-flutter's common.inc runs `flutter pub get --enforce-lockfile`
# which requires a pubspec.lock matching the exact SDK version.
# Our dev SDK (3.41) != AGL Yocto SDK (3.8), so we cannot ship a
# compatible lockfile. Instead, we generate it at build time using
# the Yocto-native Flutter SDK before the class runs --enforce-lockfile.
PUBSPEC_IGNORE_LOCKFILE = "0"

do_configure:prepend() {
    cd ${S}
    # Generate a lockfile using the Yocto-native Flutter SDK
    # This runs BEFORE common.inc's do_compile which needs --enforce-lockfile
    if [ ! -f pubspec.lock ]; then
        ${STAGING_DIR_NATIVE}/usr/share/flutter/sdk/bin/flutter pub get || true
    fi
}

# ── AGL application framework integration ────────────────────
AGL_APP_TEMPLATE = "agl-app-flutter"
AGL_APP_ID = "agl_app_store"
AGL_APP_NAME = "AGL PENS App Store"

# ── Build dependencies ───────────────────────────────────────
DEPENDS += " \
    flatpak \
    glib-2.0 \
    gtk+3 \
"

# ── Runtime dependencies ─────────────────────────────────────
RDEPENDS:${PN} += " \
    packagegroup-flatpak \
    flatpak-predefined-repos \
"

# ── Install systemd service for AGL IVI display ──────────────
do_install:append() {
    install -D -m 0644 \
        ${WORKDIR}/agl-app-flutter@agl-app-store.service \
        ${D}${systemd_system_unitdir}/agl-app-flutter@agl-app-store.service
}

# Allow network access during build for pub dependencies
do_compile[network] = "1"
do_configure[network] = "1"
