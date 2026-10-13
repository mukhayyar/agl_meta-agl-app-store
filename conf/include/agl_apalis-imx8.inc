# AGL integration for the Toradex Apalis i.MX8 (i.MX 8QuadMax / "mx8qm").
#
# The machine itself is defined by meta-toradex-nxp
# (conf/machine/apalis-imx8.conf) and already selects the NXP BSP plus the
# Toradex kernel (linux-toradex) and bootloader (u-boot-toradex). This file adds
# the AGL-side adjustments, mirroring what agl_imx8mq-evk.inc does for i.MX8:
#  * share the common AGL <-> meta-freescale fixups, and
#  * pin the graphics/multimedia stack to AGL's mainline versions on i.MX8.
#
# Reconstructed from the July build session's logs: the recovered copy carried
# this header and the `require` line, and the graphis/multimedia pins follow
# agl_imx8mq-evk.inc with the mx8qm override chain taken from meta-freescale's
# imx-base.inc (MACHINEOVERRIDES_EXTENDER:mx8qm:use-nxp-bsp). Re-verify the pin
# list against meta-toradex-nxp when the BSP layer is bumped.

require agl_imx-common.inc

# Keep the NXP BSP explicit (the Toradex machine sets this too) so the graphics
# and display stack does not fall back to the mainline drivers, which lack the
# MHDP (DisplayPort/HDMI) support this SoC needs on the Apalis carrier boards.
IMX_DEFAULT_BSP = "nxp"

# Same override chain imx-base.inc applies for mx8qm with the NXP BSP, spelled
# out explicitly so it holds whichever way IMX_DEFAULT_BSP was set earlier.
MACHINEOVERRIDES_EXTENDER:mx8qm:forcevariable = "imx-generic-bsp:imx-nxp-bsp:imxdrm:imxdpu:imxgpu:imxviv:imxgpu2d:imxgpu3d:imxvulkan:mx8-generic-bsp:mx8-nxp-bsp:mx8qm-generic-bsp:mx8qm-nxp-bsp"

# Add our own over-ride for use in a few recipes where there is conflicting
# Vivante vs etnaviv configuration.
MACHINEOVERRIDES .= ":etnaviv"

# Reset graphics-related recipes to mainline versions
PREFERRED_VERSION_weston:mx8qm-generic-bsp = "13.0.1"
PREFERRED_VERSION_wayland-protocols:mx8qm-generic-bsp = "1.33"
PREFERRED_VERSION_xwayland:mx8qm-generic-bsp = "23.2.5"
PREFERRED_VERSION_libdrm:mx8qm-generic-bsp = "2.4.120"
PREFERRED_VERSION_ffmpeg:mx8qm-generic-bsp = "6.6.%"

PREFERRED_VERSION_gstreamer1.0:mx8qm-generic-bsp = "1.22.%"
PREFERRED_VERSION_gstreamer1.0-plugins-base:mx8qm-generic-bsp = "1.22.%"
PREFERRED_VERSION_gstreamer1.0-plugins-good:mx8qm-generic-bsp = "1.22.%"
PREFERRED_VERSION_gstreamer1.0-plugins-bad:mx8qm-generic-bsp = "1.22.%"
PREFERRED_VERSION_gstreamer1.0-plugins-ugly:mx8qm-generic-bsp = "1.22.%"
PREFERRED_VERSION_gstreamer1.0-python:mx8qm-generic-bsp = "1.22.%"
PREFERRED_VERSION_gstreamer1.0-rtsp-server:mx8qm-generic-bsp = "1.22.%"
PREFERRED_VERSION_gstreamer1.0-vaapi:mx8qm-generic-bsp = "1.22.%"
PREFERRED_VERSION_gst-devtools:mx8qm-generic-bsp = "1.22.%"

# Disable to avoid warnings about missing bbappend for the preferred version in
# some scenarios.
BBMASK += "meta-freescale/recipes-multimedia/gstreamer/gstreamer1.0-plugins-base_1.24.%.bbappend"
