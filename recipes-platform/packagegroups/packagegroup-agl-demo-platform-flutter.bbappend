# ============================================================
# Append AGL App Store to the AGL IVI demo platform
# ============================================================
# This adds our app to the same packagegroup that includes the
# default AGL Flutter demo apps (homescreen, dashboard, etc.),
# so it appears in the IVI launcher automatically.
# ============================================================

RDEPENDS:${PN} += " \
    agl-app-store \
"
