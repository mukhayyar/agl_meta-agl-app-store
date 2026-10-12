#!/bin/sh
# ============================================================
# agl-store-refocus
# ============================================================
# Watches agl-compositor's app-state stream (via agl-shell-activator -l) and
# re-activates the App Store whenever any *other* application terminates.
#
# Why: the AGL launcher starts an app with `systemctl start
# agl-app-flutter@<id>.service`. That is a no-op when the instance is already
# running (the store is almost always resident), so a store that ends up behind
# another app never gets brought back to the foreground. Re-activating it
# explicitly through agl-shell-activator works around that.
#
# The activator needs an output name for ActivateApp; it defaults to the
# sole/first output itself (see the agl-shell-activator patch in this layer).
# ============================================================

STORE_ID="agl_app_store"
ACTIVATOR="/usr/bin/agl-shell-activator"
LOG_TAG="agl-store-refocus"

log() { logger -t "${LOG_TAG}" "$*"; }

log "watching compositor app-state stream for ${STORE_ID}"

while :; do
    "${ACTIVATOR}" -l 2>&1 | while read -r line; do
        # Only react to app-state traffic ...
        case "${line}" in
            *app_id*) ;;
            *) continue ;;
        esac

        # ... and never to the store's own events.
        case "${line}" in
            *"${STORE_ID}"*) continue ;;
        esac

        # TERMINATED is what the compositor emits when a client goes away; that
        # is the moment another app may have displaced the store.
        case "${line}" in
            *TERMINATED*|*DEACTIVATED*)
                log "app left the foreground (${line}); reactivating ${STORE_ID}"
                if ! "${ACTIVATOR}" -a activate -p "${STORE_ID}" >/dev/null 2>&1; then
                    log "activation of ${STORE_ID} failed"
                fi
                ;;
        esac
    done

    log "activator listener exited; restarting in 5s"
    sleep 5
done
