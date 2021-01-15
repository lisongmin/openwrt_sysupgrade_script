#!/usr/bin/env sh

_dir=$(dirname $0)

download()
{
	local openwrt_url=https://${OPENWRT_MIRROR:-$OPENWRT_REPO}/releases/${OPENWRT_VERSION}/targets/${OPENWRT_BOARD}
	local sysupgrade_file=openwrt-${OPENWRT_VERSION}-$(echo ${OPENWRT_BOARD}|tr '/' '-')-${OPENWRT_MODEL}-squashfs-sysupgrade.bin

	echo "step: download checksum file"
	curl -L -O -C - --retry 20 ${openwrt_url}/sha256sums

	local expect_checksum
	expect_checksum=$(cat sha256sums|grep ${sysupgrade_file}|awk '{print $1}')
	if [ -z "$expect_checksum" ];then
		echo "Error: Can not get checksum of ${sysupgrade_file}."
		return 1
	fi

	echo "step: download sysupgrade file"
	curl -L -O -C - --retry 20 ${openwrt_url}/${sysupgrade_file}

	local real_checksum
	real_checksum=$(sha256sum ${sysupgrade_file}|awk '{print $1}')

	if [ "$expect_checksum" != "$real_checksum" ];then
		echo "Error: Checksum miss match."
		echo "expect: $expect_checksum"
		echo "real  : $real_checksum"
		return 1
	fi

	echo "step: link sysupgrade.bin to downloaded file"
	ln -sf ${sysupgrade_file} sysupgrade.bin
}

keep_upgrade_script()
{
	grep openwrt_upgrade_script /etc/sysupgrade.conf &>/dev/null
	if [ $? -ne 0 ];then
		echo "/etc/openwrt_upgrade_script/" >> /etc/sysupgrade.conf
	fi
}

upgrade()
{
	echo "step: Upgrade."
	sysupgrade -v sysupgrade.bin
}

# source OPENWRT_BOARD
. /etc/os-release

OPENWRT_MODEL=$(sed -n 's/.*"id":\s"\([^"]\+\)",.*/\1/p' /etc/board.json)
if [ -z "$OPENWRT_MODEL" ];then
	echo "ERROR: Can not detect device model via /etc/board.json"
	exit 1
fi

for envfile in env models/${OPENWRT_MODEL}/env ; do
	if [ -e "${_dir}/${envfile}" ];then
		. "${_dir}/${envfile}"
	fi
done

mkdir -p /tmp/openwrt_upgrade
cd /tmp/openwrt_upgrade

keep_upgrade_script
download || exit $?
upgrade
