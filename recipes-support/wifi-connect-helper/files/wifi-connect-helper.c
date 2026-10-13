/* ============================================================
 * wifi-connect-helper.c — setuid-root shim
 * ============================================================
 * The Flutter UI (homescreen / App Store) runs as agl-driver, but ConnMan's
 * D-Bus policy is root-only and the kernel ignores setuid on shell scripts.
 * This tiny wrapper is the only setuid part: it switches to root and execs
 * /usr/libexec/wifi-connect-helper.sh, which does the actual connmanctl work.
 *
 * argv is passed through unchanged, so the caller uses it exactly like the
 * script:  wifi-connect-helper services | connect <service> | disconnect ...
 * ============================================================ */

#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <sys/types.h>

#define HELPER "/usr/libexec/wifi-connect-helper.sh"

int main(int argc, char **argv)
{
    /* argv is forwarded verbatim to the script. */
    (void)argc;

    if (setgid(0) != 0) {
        perror("wifi-connect-helper: setgid");
        return 1;
    }

    if (setuid(0) != 0) {
        perror("wifi-connect-helper: setuid");
        return 1;
    }

    execv(HELPER, argv);

    /* Only reached if execv failed. */
    perror("wifi-connect-helper: execv " HELPER);
    return 1;
}
