#!/usr/bin/env sh

_dir=$(dirname $0)

download()
{
	echo "step: download checksum file"
	curl -L -O -C - --retry 20 ${OPENWRT_URL}/sha256sums

	local expect_checksum
	expect_checksum=$(cat sha256sums|grep ${OPENWRT_SYSUPGRADE_FILE}|awk '{print $1}')
	if [ -z "$expect_checksum" ];then
		echo "Error: Can not get checksum of ${OPENWRT_SYSUPGRADE_FILE}."
		return 1
	fi

	echo "step: download sysupgrade file"
	curl -L -O -C - --retry 20 ${OPENWRT_URL}/${OPENWRT_SYSUPGRADE_FILE}

	local real_checksum
	real_checksum=$(sha256sum ${OPENWRT_SYSUPGRADE_FILE}|awk '{print $1}')

	if [ "$expect_checksum" != "$real_checksum" ];then
		echo "Error: Checksum miss match."
		echo "expect: $expect_checksum"
		echo "real  : $real_checksum"
		return 1
	fi

	echo "step: link sysupgrade.bin to downloaded file"
	ln -sf ${OPENWRT_SYSUPGRADE_FILE} sysupgrade.bin
}

keep_upgrade_script()
{
	grep openwrt_upgrade_script /etc/sysupgrade.conf &>/dev/null
	if [ $? -ne 0 ];then
		echo "/etc/openwrt_upgrade_script/" >> /etc/sysupgrade.conf
	fi
}

save_user_installed_packages()
{
	echo "step: save user installed packages"
	awk '/^Package:/{PKG= $2};  /^Status: .*user installed/{print PKG}' /usr/lib/opkg/status > "${_dir}/.user_installed_packages"
}


upgrade()
{
	echo "step: Upgrade."
	sysupgrade -v sysupgrade.bin
}

. ${_dir}/env
prepare_env "${_dir}"

keep_upgrade_script
save_user_installed_packages

mkdir -p /tmp/openwrt_upgrade
cd /tmp/openwrt_upgrade

download || exit $?
upgrade
