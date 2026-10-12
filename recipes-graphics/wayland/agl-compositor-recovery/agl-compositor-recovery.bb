SUMMARY = "Self-heal the AGL UI after an agl-compositor crash without a reboot"
DESCRIPTION = "systemd drop-ins that make a compositor SIGSEGV/watchdog recovery \
self-heal to the home screen: agl-compositor gains Restart=on-failure plus an \
ExecStartPost that re-binds the home screen to the fresh instance (covering the \
crash/socket-activation path PartOf= misses), and the flutter app template is \
bound to the compositor lifecycle (PartOf=/After=). Pairs with the agl-compositor \
and agl-shell-activator crash fixes. The App Store instance's Restart=always drop-in \
is shipped by agl-store-refocus, which owns that path."
LICENSE = "MIT"
LIC_FILES_CHKSUM = "file://${COMMON_LICENSE_DIR}/MIT;md5=0835ade698e0bcf8506ecda2f7b4f302"

SRC_URI = " \
    file://10-recovery.conf \
    file://10-compositor-binding.conf \
"

# systemctl (used by the ExecStartPost heal) comes from systemd.
RDEPENDS:${PN} = "systemd"

# Drop-ins are installed under /etc (the admin override path) so they take
# precedence and never collide with the .service.d directories the upstream
# recipes package under /usr/lib.
#
# Note: the App Store restart drop-in lives here (not in agl-store-refocus) so
# that exactly one recipe owns that path -- two recipes installing the same
# /etc file would break the image build with a file conflict.
do_install() {
    install -d ${D}${sysconfdir}/systemd/system/agl-compositor.service.d
    install -m 0644 ${WORKDIR}/10-recovery.conf \
        ${D}${sysconfdir}/systemd/system/agl-compositor.service.d/

    install -d ${D}${sysconfdir}/systemd/system/agl-app-flutter@.service.d
    install -m 0644 ${WORKDIR}/10-compositor-binding.conf \
        ${D}${sysconfdir}/systemd/system/agl-app-flutter@.service.d/
}

FILES:${PN} += "${sysconfdir}/systemd/system/ \
                ${sysconfdir}/systemd/system/agl-compositor.service.d \
                ${sysconfdir}/systemd/system/agl-app-flutter@.service.d"
