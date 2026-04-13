# ============================================================
# Generic Flatpak bbappend — catches any version
# ============================================================
# Applies AGL-specific tweaks regardless of the Flatpak version
# provided by the base layer (meta-oe, meta-flatpak, etc.)
# ============================================================

EXTRA_OECONF += " \
    --with-system-install-dir=${FLATPAK_SYSTEM_DIR} \
    --disable-documentation \
    --disable-docbook-docs \
"
