#!/usr/bin/env sh

# This is a script to restart openwrt network if gateway is unreachable.
# Usage:
# /bin/sh ./restart_network_on_unreachable.sh gateway 240
#
# parameters:
# 1. the first parameter is host to ping, can be ip address, domain name, or 'gateway'
#    when set to 'gateway', we will get the target ip via 'ip ro'.
#    default is 'gateway'
# 2. the second parameter is seconds to wait. Note that the value is not precise, there may be an error of about 10s
#    default is 240
#
# we usually add this script to crontab, so it can running periodly.
# root@OpenWrt:~# crontab -l
# * * * * * /bin/sh /etc/openwrt_upgrade_script/bin/restart_network_on_unreachable.sh gateway 240

trap "echo Exited!; exit;" SIGINT SIGTERM

PING_INTERVAL=2
PING_TIMES=3
PING_WAIT=10

get_gateway()
{
    ip -o ro|grep default|awk '{print $3}'
}

peer_reachable()
{
    local peer="$1"
    local try_times="${2:-3}"

    local peer_is_gateway=1
    if [ "$peer" = "gateway" ];then
        peer_is_gateway=0
        peer=$(get_gateway)
    fi

    # return quickly if it is reachable.
    ping -q -c 1 -W 1 "$peer"
    if [ $? -eq 0 ]; then
        return 0
    fi

    # test to timeout
    for retry in `seq $try_times` ; do
        if [ "$peer_is_gateway" -eq 0 ]; then
            peer=$(get_gateway)
        fi
        if [ -z "$peer" ];then
            sleep $PING_WAIT
            continue
        fi
        ping -q -i $PING_INTERVAL -c $PING_TIMES -W $PING_WAIT "$peer"
        if [ $? -eq 0 ]; then
            return 0
        fi
    done
    return 1
}

on_peer_unreachable()
{
    local action="$1"
    echo >&2 "$(date) <Warn> peer is unreachable"

    case "$action" in
        restart_openwrt_network)
            /etc/init.d/network restart
            ;;
        *)
            ;;
    esac
}

peer="${1:-gateway}"
seconds="${2:-240}"
retry_times=$(( (seconds + 5) / 10))
peer_reachable "$peer" "$retry_times"
if [ $? -eq 0 ]; then
    exit 0
fi

on_peer_unreachable "restart_openwrt_network"
