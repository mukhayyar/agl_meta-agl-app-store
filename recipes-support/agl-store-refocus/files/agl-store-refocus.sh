#!/bin/sh
# ============================================================
# agl-store-refocus
# ============================================================
# Belt-and-suspenders workaround so the App Store always comes back to the
# foreground.
#
# Why: the AGL launcher starts an app with `systemctl start
# agl-app-flutter@<id>.service`, which is a no-op for an instance that is already
# running -- and the store is resident almost all the time. So once another app
# is placed on top, nothing brings the store back.
#
# This watcher tails the journal for agl-shell's app-state events and, whenever
# any *other* app reports state 1 (TERMINATED), re-activates the store through
# agl-shell-activator. The activator is run as the AGL driver user, the same
# identity the compositor expects for shell clients.
# ============================================================

STORE_ID="agl_app_store"
ACTIVATOR="/usr/bin/agl-shell-activator"
JOURNAL_MATCH="agl_shell_app_state"
# Output to activate on. Leave empty to let agl-shell-activator pick the sole
# output itself (it no longer requires -o).
OUTPUT="${AGL_STORE_OUTPUT:-HDMI-A-1}"
LOG_TAG="agl-store-refocus"

log() { logger -t "${LOG_TAG}" "$*"; }

log "watching ${JOURNAL_MATCH} events (store=${STORE_ID}, output=${OUTPUT:-auto})"

# -f follow, -o cat: message text only, -n 0: do not replay history on start.
journalctl -f -o cat -n 0 2>/dev/null | while read -r line; do
    case "${line}" in
        *"${JOURNAL_MATCH}"*"app_state event app_id"*) ;;
        *) continue ;;
    esac

    app_id=$(printf '%s' "${line}" | sed -n 's/.*app_id=\([^ ]*\).*/\1/p')
    state=$(printf '%s' "${line}" | sed -n 's/.*state=\([0-9]*\).*/\1/p')

    # state 1 == AGL_SHELL_APP_STATE_TERMINATED
    [ "${state}" = "1" ] || continue
    [ "${app_id}" = "${STORE_ID}" ] && continue

    log "app '${app_id}' terminated; re-activating ${STORE_ID}"

    if [ -n "${OUTPUT}" ]; then
        su agl-driver -s /bin/sh -c \
            "${ACTIVATOR} -a activate -p ${STORE_ID} -o ${OUTPUT}" 2>&1
    else
        su agl-driver -s /bin/sh -c \
            "${ACTIVATOR} -a activate -p ${STORE_ID}" 2>&1
    fi
done
