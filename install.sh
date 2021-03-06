#/usr/bin/env sh

_dir=$(dirname $0)

. ${_dir}/env
prepare_env "${_dir}"

if [ -n "$OPENWRT_MIRROR" ];then
	echo "step: setting repo mirrors."
	sed -i "s%${OPENWRT_REPO}%${OPENWRT_MIRROR}%g" /etc/opkg/distfeeds.conf
fi
opkg update

echo "step: enable tls support for wget, curl"
opkg list-installed|grep libustream &>/dev/null
if [ $? -ne 0 ];then
	opkg install libustream-${OPENWRT_SSL_LIB} || exit $?
fi
opkg install ca-bundle || exit $?

echo "step: enable https for opkg."
sed -i 's/http:/https:/g' /etc/opkg/distfeeds.conf
opkg update

echo "step: install common softwares"
opkg install curl rsync || exit $?

if [ "$OPENWRT_IS_SNAPSHOT" = "true" ];then
	opkg install luci
fi

echo "step: enable https for uhttpd"
if [ "$OPENWRT_SSL_LIB" = "wolfssl" ];then
	LUCI_SSL=luci-ssl
else
	LUCI_SSL=luci-ssl-"$OPENWRT_SSL_LIB"
fi
opkg install $LUCI_SSL libuhttpd-${OPENWRT_SSL_LIB} || exit $?
/etc/init.d/uhttpd reload

echo "step: restore user installed packages"
if [ -e "$_dir/.user_installed_packages" ]; then
	opkg install $(cat ${_dir}/.user_installed_packages)
fi
