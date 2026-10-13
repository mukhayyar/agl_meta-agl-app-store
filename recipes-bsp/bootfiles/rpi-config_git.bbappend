# Force a 1920x1080@60 CVT mode on the HDMI output.
#
# The AGL demo UI (and the App Store) is laid out for 1080p, but the Pi's
# default mode negotiation can land on a mode the panel/adapter reports oddly,
# leaving the UI scaled or clipped. hdmi_cvt with the 16:9 aspect flag pins the
# mode; the line is appended to config.txt by the rpi-config recipe itself.
RPI_EXTRA_CONFIG:append = "\nhdmi_cvt=1920 1080 60 6 0 0 0"
