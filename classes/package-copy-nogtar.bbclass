# ============================================================
# package-copy-nogtar — host build workaround (GNU tar >= 1.35 + pseudo)
# ============================================================
# Work around GNU tar >= 1.35 aborting under pseudo during do_package.
#
# perform_packagecopy() in package.bbclass copies D -> PKGD with a
# "tar -cf - ... | tar -xf -" pipe. GNU tar 1.35 opens the destination
# directory with an *at()/O_PATH file descriptor that this pseudo (1.9.0,
# SRCREV 28dcefb) does not track, so every mkdirat() fails with EFAULT:
#     unknown base path for fd 4, path ...
#     tar: ./usr/lib: Cannot mkdir: Bad address
# This breaks do_package for ALL recipes on hosts whose /usr/bin/tar was
# upgraded to 1.35 (OE's tar-native is 1.35 too, so switching to it does not
# help). cp uses the openat/mkdirat pattern pseudo does track, so we copy with
# cp instead. cp -a preserves hardlinks, permissions and (fake, via pseudo)
# ownership; --sparse=always keeps sparse files sparse; we then drop the
# sysroot-only staging dir the original tar excluded.
#
# Remove this class (and the USER_CLASSES entry in local.conf) once pseudo is
# updated to handle tar 1.35, or the host tar is downgraded.
#
# Usage (local.conf):
#     USER_CLASSES += "package-copy-nogtar"
#
# It must go in USER_CLASSES, not INHERIT: INHERIT is expanded before
# PACKAGE_CLASSES, so `package_rpm` (via package.bbclass) would be inherited
# after this class and its perform_packagecopy() would win. Verified on a trout
# tree with tar 1.35: with INHERIT the do_package failure below persists, with
# USER_CLASSES linux-libc-headers:do_package completes and the log is clean.

python perform_packagecopy () {
    import subprocess

    dest = d.getVar('D')
    dvar = d.getVar('PKGD')

    # Preserve hardlinks and sparse files, exclude ./sysroot-only.
    cmd = "cp -a --sparse=always %s/. %s/ && rm -rf %s/sysroot-only" % (dest, dvar, dvar)
    subprocess.check_output(cmd, shell=True, stderr=subprocess.STDOUT)

    # replace RPATHs for the nativesdk binaries, to make them relocatable
    if bb.data.inherits_class('nativesdk', d) or bb.data.inherits_class('cross-canadian', d):
        rpath_replace(dvar, d)
}
perform_packagecopy[cleandirs] = "${PKGD}"
perform_packagecopy[dirs] = "${PKGD}"
