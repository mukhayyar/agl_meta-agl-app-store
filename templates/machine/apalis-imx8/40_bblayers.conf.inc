# Toradex Apalis i.MX8 (i.MX 8QuadMax) BSP layers.
#
# meta-freescale + meta-freescale-3rdparty provide the i.MX base that the
# Toradex layers extend; meta-toradex-nxp defines the apalis-imx8 machine and
# depends on meta-toradex-bsp-common. Must be parsed after the qt5/etc. layers
# so meta-freescale/dynamic-layers are recognised correctly.
BBLAYERS =+ "\
  ${METADIR}/bsp/meta-freescale \
  ${METADIR}/bsp/meta-freescale-3rdparty \
  ${METADIR}/bsp/meta-toradex-bsp-common \
  ${METADIR}/bsp/meta-toradex-nxp \
  "