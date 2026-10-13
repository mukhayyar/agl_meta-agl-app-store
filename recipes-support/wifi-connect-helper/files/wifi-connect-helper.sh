#!/bin/sh
# ============================================================
# wifi-connect-helper.sh — privileged WiFi operations for the AGL PENS UI
# ============================================================
# Runs as root (through the setuid wrapper /usr/bin/wifi-connect-helper).
#
# Usage:
#   wifi-connect-helper services              # raw `connmanctl services`
#   wifi-connect-helper status  <service>     # raw `connmanctl services <svc>`
#   wifi-connect-helper connect <service>     # passphrase read from stdin
#   wifi-connect-helper disconnect <service>
#
# Why a helper at all: ConnMan's D-Bus policy is root-only and the Flutter UI
# runs as agl-driver, so its connmanctl calls are refused. The kernel ignores
# setuid on shell scripts, hence the C shim in front of this script.
# ============================================================

set -eu

CONNMAN_DIR="/var/lib/connman"
CMD="${1:-}"
[ $# -gt 0 ] && shift

case "${CMD}" in
    services)
        exec connmanctl services
        ;;

    status)
        SVC="${1:?status needs a service name}"
        exec connmanctl services "${SVC}"
        ;;

    connect)
        SVC="${1:?connect needs a service name}"
        # Passphrase arrives on stdin so it never shows up in `ps`.
        PSK=""
        if [ ! -t 0 ]; then
            IFS= read -r PSK || PSK=""
        fi

        # ConnMan keeps one .config per provisioned network and favours
        # everything it finds, which used to leave two networks "connected"
        # (one of them without a route, so no internet). Keep exactly one.
        rm -f "${CONNMAN_DIR}"/wifi_*.config

        # The service id carries the SSID hex: wifi_<mac>_<ssidhex>_managed_psk
        case "${SVC}" in
            wifi_*_managed_psk|wifi_*_managed_ieee8021x)
                SSID_HEX=$(printf '%s' "${SVC}" | sed -E 's/^wifi_[0-9a-f]+_//; s/_managed.*$//')
                ;;
            *)
                SSID_HEX=""
                ;;
        esac

        mkdir -p "${CONNMAN_DIR}"
        if [ -n "${SSID_HEX}" ]; then
            {
                echo "[service_${SVC}]"
                echo "Type = wifi"
                echo "Name = ${SVC}"
                echo "SSID = ${SSID_HEX}"
                if [ -n "${PSK}" ]; then
                    echo "Passphrase = ${PSK}"
                fi
                echo "AutoConnect = true"
            } > "${CONNMAN_DIR}/${SVC}.config"
        fi

        # Ask ConnMan to use it now (the config above makes it stick across
        # reboots / re-associations).
        if [ -n "${PSK}" ]; then
            printf '%s\n' "${PSK}" | connmanctl connect "${SVC}"
        else
            connmanctl connect "${SVC}"
        fi
        ;;

    disconnect)
        SVC="${1:?disconnect needs a service name}"
        connmanctl disconnect "${SVC}" || true
        connmanctl config --remove "${SVC}" >/dev/null 2>&1 || true
        rm -f "${CONNMAN_DIR}/${SVC}.config"
        ;;

    *)
        echo "usage: wifi-connect-helper {services|status <svc>|connect <svc>|disconnect <svc>}" >&2
        exit 2
        ;;
esac
