SUMMARY = "Privileged ConnMan helper for the AGL PENS UI"
DESCRIPTION = "The Flutter UI runs as agl-driver, while ConnMan's D-Bus policy is \
root-only -- so a scan/connect from the WiFi page is denied before it reaches \
connman. The kernel also ignores setuid on shell scripts, so this ships a tiny \
setuid C shim (/usr/bin/wifi-connect-helper, 4755) that drops nothing and execs \
the real script (/usr/libexec/wifi-connect-helper.sh, 0755) as root. The script \
wraps `connmanctl services/status/connect/disconnect`, removes competing \
wifi_*.config files and writes the provisioning config with the hex SSID so \
favourites auto-connect."
LICENSE = "MIT"
LIC_FILES_CHKSUM = "file://${COMMON_LICENSE_DIR}/MIT;md5=0835ade698e0bcf8506ecda2f7b4f302"

SRC_URI = " \
    file://wifi-connect-helper.c \
    file://wifi-connect-helper.sh \
"

# connmanctl comes from connman; grep/sed/awk from busybox or coreutils.
RDEPENDS:${PN} += "connman"

# The helper is only reachable through the setuid wrapper, and the wrapper is
# useless without the root-only script it execs.
FILES:${PN} += " \
    ${bindir}/wifi-connect-helper \
    ${libexecdir}/wifi-connect-helper.sh \
"

do_compile() {
    # Small standalone C program: no configure, no makefile.
    ${CC} ${CFLAGS} ${LDFLAGS} ${WORKDIR}/wifi-connect-helper.c -o ${WORKDIR}/wifi-connect-helper
}

do_install() {
    install -d ${D}${bindir}
    install -m 0755 ${WORKDIR}/wifi-connect-helper ${D}${bindir}/wifi-connect-helper
    # setuid root: the script needs root to talk to ConnMan over D-Bus.
    chmod 4755 ${D}${bindir}/wifi-connect-helper

    install -d ${D}${libexecdir}
    install -m 0755 ${WORKDIR}/wifi-connect-helper.sh ${D}${libexecdir}/wifi-connect-helper.sh
}

# ldflags/compile happen here, but the wrapper must never be run during the
# build; pkg_postinst is empty (no postinst) so the setuid bit is preserved.
pkg_postinst:${PN}() {
    :
}
