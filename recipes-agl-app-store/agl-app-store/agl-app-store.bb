SUMMARY = "AGL PENS App Store"
DESCRIPTION = "Application Store for Automotive Grade Linux (AGL) — \
A Flutter-based embedded storefront that provides a unified interface \
for browsing, installing, and managing Flatpak applications from both \
PENSHub (private repository) and Flathub (public repository). \
Developed as part of the PENS Final Project (Proyek Akhir)."
AUTHOR = "Muhammad Tsaqif Mukhayyar <tsaqifmukhayyar@gmail.com>"
HOMEPAGE = "https://agl-store.cyou"
LICENSE = "MIT"
LIC_FILES_CHKSUM = "file://LICENSE;md5=f44a62fe5f7a8f1c09e7c23142689840"
SECTION = "graphics"

PN = "agl-app-store"

SRC_URI = "gitsm://github.com/mukhayyar/agl-app-store.git;protocol=https;branch=main \
           file://agl-app-flutter@agl_app_store.service \
           "

# Pinned for reproducible builds; bump together with the application.
# Use "${AUTOREV}" only for throwaway development images.
SRCREV = "ce1cf09a355b6f1b0fd6bd48f687ecc3e48dc98a"

S = "${WORKDIR}/git"

inherit agl-app flutter-app

# ── Flutter configuration ────────────────────────────────────
PUBSPEC_APPNAME = "agl_app_store"
FLUTTER_APPLICATION_INSTALL_PREFIX = "/usr/share/flutter"
FLUTTER_BUILD_ARGS = "bundle -v"

# ── Lockfile handling ────────────────────────────────────────
# The application repository deliberately does not carry a pubspec.lock
# that matches the Yocto Flutter SDK.  meta-flutter supports this case
# natively: with PUBSPEC_IGNORE_LOCKFILE = "1" it deletes the stale
# lockfile and regenerates it with the SDK's own `dart pub get` before
# running `flutter pub get --enforce-lockfile` (see
# external/meta-flutter/conf/include/common.inc).  The same setting is
# used by the AGL first-party Flutter recipes (e.g.
# flutter-ics-homescreen_git.bb).
PUBSPEC_IGNORE_LOCKFILE = "1"

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
    agl-flatpak-polkit-rule \
"

# ── systemd unit ─────────────────────────────────────────────
# The file *must* be named <AGL_APP_TEMPLATE>@<AGL_APP_ID>.service:
# the agl-app class creates exactly that instance symlink to the
# template unit (agl-app-flutter@.service) and applaunchd starts the
# application by that instance name.  A unit installed under any other
# name is never referenced.
do_install:append() {
    install -D -m 0644 \
        ${WORKDIR}/agl-app-flutter@agl_app_store.service \
        ${D}${systemd_system_unitdir}/agl-app-flutter@agl_app_store.service
}

# The store is launched on demand from the AGL launcher (applaunchd).
# To auto-start it at boot instead, uncomment (the unit above already
# carries an [Install] section):
#SYSTEMD_SERVICE:${PN} = "agl-app-flutter@agl_app_store.service"
#SYSTEMD_AUTO_ENABLE = "enable"

# meta-flutter regenerates pubspec.lock during do_compile
do_compile[network] = "1"
