SUMMARY = "Flatpak runtime support for AGL App Store"
DESCRIPTION = "Packagegroup that pulls in Flatpak, OSTree, and supporting \
utilities needed to install, run, and manage Flatpak applications on an \
AGL embedded target."
LICENSE = "MIT"

inherit packagegroup

RDEPENDS:${PN} = " \
    flatpak \
    ostree \
    ca-certificates \
    gnupg \
    glib-networking \
"
