FILESEXTRAPATHS:prepend := "${THISDIR}/agl-compositor/files:"

# Fix a reproducible SIGSEGV in agl-compositor under heavy surface-activation
# churn: a use-after-free of output->previous_active (never cleared when the
# surface is freed) plus two NULL derefs on the deactivate / app-state path.
# No upstream fix exists for these; defensive backport. See the patch header.
SRC_URI += "file://0001-Fix-SIGSEGV-on-surface-activation-deactivation-churn.patch"
