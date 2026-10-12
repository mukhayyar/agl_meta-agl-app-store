SUMMARY = "Refocus workaround for the AGL PENS App Store"
DESCRIPTION = "A root systemd service that watches agl-compositor's app-state \
stream and re-activates the App Store (via agl-shell-activator) when any other \
app terminates, working around the launcher's no-op systemctl-start on the \
already-running store. Pair with the launcher activation fix in the homescreen \
(flutter-agl: lib/data/data_providers/app_launcher.dart passes the compositor's \
output name to ActivateApp, without which the request is a silent no-op)."
LICENSE = "MIT"
LIC_FILES_CHKSUM = "file://${COMMON_LICENSE_DIR}/MIT;md5=0835ade698e0bcf8506ecda2f7b4f302"

# The systemd instance the store runs as (agl-app-flutter@<STORE_INSTANCE>).
STORE_INSTANCE = "agl_app_store"

SRC_URI = " \
    file://agl-store-refocus.sh \
    file://agl-store-refocus.service \
"

# journalctl (systemd) and the activator binary the watcher drives.
RDEPENDS:${PN} = "systemd agl-shell-activator"

inherit systemd
SYSTEMD_SERVICE:${PN} = "agl-store-refocus.service"
SYSTEMD_AUTO_ENABLE = "enable"

do_install() {
    install -d ${D}${bindir}
    install -m 0755 ${WORKDIR}/agl-store-refocus.sh ${D}${bindir}/agl-store-refocus

    install -d ${D}${systemd_system_unitdir}
    install -m 0644 ${WORKDIR}/agl-store-refocus.service ${D}${systemd_system_unitdir}/
}

FILES:${PN} += "${bindir}/agl-store-refocus ${systemd_system_unitdir}"
