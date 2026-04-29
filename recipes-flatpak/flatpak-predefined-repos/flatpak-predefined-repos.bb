SUMMARY = "Pre-configured Flatpak remote repositories for AGL App Store"
DESCRIPTION = "Installs configuration scripts that register PENSHub and \
Flathub as Flatpak remote repositories on first boot, so the AGL App Store \
Flutter client can browse and install applications immediately."
LICENSE = "MIT"
LIC_FILES_CHKSUM = "file://${COMMON_LICENSE_DIR}/MIT;md5=0835ade698e0bcf8506ecda2f7b4f302"

SRC_URI = " \
    file://setup-flatpak-repos.sh \
    file://penshub-public.gpg \
"

RDEPENDS:${PN} = "flatpak"

do_install() {
    # Install the setup script
    install -d ${D}${bindir}
    install -m 0755 ${WORKDIR}/setup-flatpak-repos.sh ${D}${bindir}/setup-flatpak-repos

    # Install the bundled PENSHub GPG public key so first-boot setup
    # does not depend on network access to fetch the key.
    install -d ${D}${datadir}/flatpak-predefined-repos
    install -m 0644 ${WORKDIR}/penshub-public.gpg \
        ${D}${datadir}/flatpak-predefined-repos/penshub-public.gpg

    # Install systemd oneshot service to run on first boot
    install -d ${D}${systemd_system_unitdir}
    cat > ${D}${systemd_system_unitdir}/flatpak-repos-setup.service << 'UNIT'
[Unit]
Description=Configure Flatpak remote repositories (PENSHub + Flathub)
After=network-online.target
Wants=network-online.target
ConditionPathExists=!/var/lib/flatpak/.repos-configured

[Service]
Type=oneshot
ExecStart=/usr/bin/setup-flatpak-repos
ExecStartPost=/bin/touch /var/lib/flatpak/.repos-configured
RemainAfterExit=yes

[Install]
WantedBy=multi-user.target
UNIT
}

inherit systemd
SYSTEMD_SERVICE:${PN} = "flatpak-repos-setup.service"
SYSTEMD_AUTO_ENABLE = "enable"

FILES:${PN} += " \
    ${bindir}/setup-flatpak-repos \
    ${datadir}/flatpak-predefined-repos/penshub-public.gpg \
    ${systemd_system_unitdir}/flatpak-repos-setup.service \
"
