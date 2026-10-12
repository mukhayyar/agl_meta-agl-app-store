SUMMARY = "Polkit rule so AGI apps can manage system-wide Flatpak installs"
DESCRIPTION = "The AGL PENS App Store drives `flatpak install/uninstall --system` \
from a systemd unit, where no interactive polkit agent exists -- every operation \
would otherwise be denied with 'not authorized'. This rule authorises the AGL \
driver user for the org.freedesktop.Flatpak.* system-helper actions. Mirrors \
meta-agl's polkit-rule-agl-app, including the polkitd-owned 0700 rules directory."
LICENSE = "MIT"
LIC_FILES_CHKSUM = "file://${COMMON_LICENSE_DIR}/MIT;md5=0835ade698e0bcf8506ecda2f7b4f302"

SRC_URI = "file://10-agl-flatpak-store.rules"

DEPENDS += "polkit"

inherit useradd features_check
REQUIRED_DISTRO_FEATURES = "polkit"

do_install() {
    install -m 700 -d ${D}${datadir}/polkit-1/rules.d
    chown polkitd:root ${D}${datadir}/polkit-1/rules.d
    install -m 0644 ${WORKDIR}/10-agl-flatpak-store.rules ${D}${datadir}/polkit-1/rules.d
}

USERADD_PACKAGES = "${PN}"
USERADD_PARAM:${PN} += "--system --no-create-home --user-group --home-dir ${sysconfdir}/polkit-1 polkitd;"

FILES:${PN} += "${datadir}/polkit-1/rules.d/*.rules"
