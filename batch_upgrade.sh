#!/usr/bin/env bash

host="$1"

./upload_script.sh $host || exit 1

ssh $host << EOF
cd /etc/openwrt_upgrade_script
./upgrade.sh
EOF

echo "step: waiting $host start up"
for x in `seq 200` ; do
    ssh -o ConnectTimeout=5 $host ls &>/dev/null
    if [ $? -eq 0 ];then
        break
    fi
    sleep 1
done

if [ $x -ge 200 ];then
    echo "Error: waiting connect to $host timeout, you should execute ./install.sh manually."
    exit 1
fi

ssh $host << EOF
cd /etc/openwrt_upgrade_script
./install.sh
EOF

