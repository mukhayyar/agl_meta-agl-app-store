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

# XWayland bridge — many flatpak GUI apps (Filezilla, GIMP, LibreOffice,
# anything built against wxWidgets/GTK2/Qt-X11) declare `--socket=x11`
# or `--socket=fallback-x11` in their manifest and cannot render on a
# pure-Wayland compositor without an X server proxy. xwayland exposes
# an X11 display backed by the Wayland compositor so those apps work.
#
# Gated on DISTRO_FEATURES so images that keep x11 off stay slim — if
# you never ship legacy X11 apps, don't flip `x11` in your distro include.
RDEPENDS:${PN} += "${@bb.utils.contains('DISTRO_FEATURES', 'x11', 'xwayland', '', d)}"
