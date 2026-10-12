SUMMARY = "Pre-create /tmp/.X11-unix for Flatpak X11 sandboxes"
DESCRIPTION = "Flatpak apps that use the X11 socket (--socket=x11 / \
--socket=fallback-x11) bind /tmp/.X11-unix into their sandbox. On AGL /tmp is a \
tmpfs that is empty at boot, so the bind fails and the app dies at startup \
before XWayland has created the directory. This recipe ships a systemd-tmpfiles \
entry that recreates the X11 socket directory on every boot, so legacy \
GTK/Qt-X11/wxWidgets Flatpak apps (GIMP, LibreOffice, FileZilla, ...) can start \
on the Wayland-only AGL compositor."
LICENSE = "MIT"
LIC_FILES_CHKSUM = "file://${COMMON_LICENSE_DIR}/MIT;md5=0835ade698e0bcf8506ecda2f7b4f302"

SRC_URI = "file://x11-tmpdir.conf"

do_install() {
    install -d ${D}${sysconfdir}/tmpfiles.d
    install -m 0644 ${WORKDIR}/x11-tmpdir.conf ${D}${sysconfdir}/tmpfiles.d/
}

FILES:${PN} += "${sysconfdir}/tmpfiles.d/x11-tmpdir.conf"
