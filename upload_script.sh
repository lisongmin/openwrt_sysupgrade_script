#!/usr/bin/env bash

_dir=$(dirname $0)

host=$1
if [ -z "$host" ];then
    echo "Error: target should be specified."
    exit 1
fi

rsync -rlptvC ${_dir} ${host}:/etc/openwrt_upgrade_script/
