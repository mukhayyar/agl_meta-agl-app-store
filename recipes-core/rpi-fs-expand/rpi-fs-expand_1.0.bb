SUMMARY = "Expand the root partition and filesystem to fill the SD card on first boot"
DESCRIPTION = "AGL's .wic images are built with a fixed-size rootfs, so a 32/64 GB card \
ends up with only a few GB usable and the rest unpartitioned -- every build then runs \
out of space. This ships a first-boot oneshot service that grows the root partition \
(growpart) and the filesystem (resize2fs, online for ext4) to the card's real capacity \
and drops a flag so it never runs again."
LICENSE = "MIT"
LIC_FILES_CHKSUM = "file://${COMMON_LICENSE_DIR}/MIT;md5=0835ade698e0bcf8506ecda2f7b4f302"

SRC_URI = " \
    file://rpi-fs-expand.sh \
    file://rpi-fs-expand.service \
    file://98-rpi-fs-expand.preset \
"

# parted grows the partition table entry (cloud-utils-growpart is not in the AGL
# trout manifest), resize2fs grows the filesystem online.
RDEPENDS:${PN} += "parted e2fsprogs-resize2fs"

inherit systemd
SYSTEMD_SERVICE:${PN} = "rpi-fs-expand.service"
SYSTEMD_AUTO_ENABLE = "enable"

do_install() {
    install -d ${D}${sbindir}
    install -m 0755 ${WORKDIR}/rpi-fs-expand.sh ${D}${sbindir}/rpi-fs-expand

    install -d ${D}${systemd_system_unitdir}
    install -m 0644 ${WORKDIR}/rpi-fs-expand.service ${D}${systemd_system_unitdir}/

    # Preset as well as SYSTEMD_AUTO_ENABLE: preset-all (which images run) and
    # the systemd class' own enablement both end up enabling the unit, and the
    # service is idempotent either way.
    install -d ${D}${libdir}/systemd/system-preset
    install -m 0644 ${WORKDIR}/98-rpi-fs-expand.preset \
        ${D}${libdir}/systemd/system-preset/98-rpi-fs-expand.preset
}

FILES:${PN} += " \
    ${sbindir}/rpi-fs-expand \
    ${systemd_system_unitdir}/rpi-fs-expand.service \
    ${libdir}/systemd/system-preset/98-rpi-fs-expand.preset \
"
