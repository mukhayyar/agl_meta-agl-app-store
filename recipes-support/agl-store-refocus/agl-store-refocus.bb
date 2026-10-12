SUMMARY = "Refocus workaround for the AGL PENS App Store"
DESCRIPTION = "A root systemd service that watches agl-compositor's app-state \
stream in the journal and re-activates the App Store (via agl-shell-activator) \
when any other app terminates, working around the launcher's no-op \
systemctl-start on the already-running store. Also adds Restart=always to the \
store service instance for crash resilience. Pair with the launcher activation \
fix in the homescreen (flutter-agl)."
LICENSE = "MIT"
LIC_FILES_CHKSUM = "file://${COMMON_LICENSE_DIR}/MIT;md5=0835ade698e0bcf8506ecda2f7b4f302"

# The systemd instance the store runs as (agl-app-flutter@<STORE_INSTANCE>).
STORE_INSTANCE = "agl_app_store"

SRC_URI = " \
    file://agl-store-refocus.sh \
    file://agl-store-refocus.service \
    file://store-restart.conf \
"

# journalctl (systemd), su (shadow), and the activator binary.
RDEPENDS:${PN} = "systemd shadow agl-shell-activator"

inherit systemd
SYSTEMD_SERVICE:${PN} = "agl-store-refocus.service"
SYSTEMD_AUTO_ENABLE = "enable"

do_install() {
    install -d ${D}${bindir}
    install -m 0755 ${WORKDIR}/agl-store-refocus.sh ${D}${bindir}/agl-store-refocus

    install -d ${D}${systemd_system_unitdir}
    install -m 0644 ${WORKDIR}/agl-store-refocus.service ${D}${systemd_system_unitdir}/

    # Restart=always for the store instance only (not the agl-app-flutter@
    # template), so other apps still close normally and the store's own close
    # button -- an explicit `systemctl stop` -- is not overridden.
    install -d ${D}${sysconfdir}/systemd/system/agl-app-flutter@${STORE_INSTANCE}.service.d
    install -m 0644 ${WORKDIR}/store-restart.conf \
        ${D}${sysconfdir}/systemd/system/agl-app-flutter@${STORE_INSTANCE}.service.d/10-restart.conf
}

FILES:${PN} += "${bindir}/agl-store-refocus \
                ${systemd_system_unitdir} \
                ${sysconfdir}/systemd/system/agl-app-flutter@${STORE_INSTANCE}.service.d"
