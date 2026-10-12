FILESEXTRAPATHS:prepend := "${THISDIR}/agl-shell-activator/files:"

# Fix: agl-shell-activator SIGSEGV (std::logic_error, construction from null)
# when `-a activate` is invoked without `-o <output>`. Default to the sole/first
# output instead of crashing. See the patch for details.
SRC_URI += "file://0001-main-don-t-crash-on-activate-without-an-output.patch"
