SUMMARY = "Polkit rule allowing AGL applications to manage system-wide Flatpak installs"
DESCRIPTION = "The AGL PENS App Store drives `flatpak install/uninstall --system` \
from a systemd unit, where no interactive polkit agent exists -- every operation \
would otherwise be denied with 'not authorized'. This rule authorises the AGL \
application user (and root) for the Flatpak system-helper D-Bus actions, so the \
App Store can install, update and remove applications unattended. Pair with \
`polkit` in DISTRO_FEATURES (meta-oe's flatpak recipe requires it) and with \
packagegroup-flatpak."
LICENSE = "MIT"
LIC_FILES_CHKSUM = "file://${COMMON_LICENSE_DIR}/MIT;md5=0835ade698e0bcf8506ecda2f7b4f302"

SRC_URI = "file://50-agl-flatpak.rules"

# The rules are consumed by polkitd itself, pulled in by flatpak.
RDEPENDS:${PN} = "polkit"

do_install() {
    install -d ${D}${datadir}/polkit-1/rules.d
    install -m 0644 ${WORKDIR}/50-agl-flatpak.rules ${D}${datadir}/polkit-1/rules.d/
}

FILES:${PN} += "${datadir}/polkit-1/rules.d"
