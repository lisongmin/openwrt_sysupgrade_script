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
opkg install libustream-openssl ca-bundle || exit $?

echo "step: enable https for opkg."
sed -i 's/http:/https:/g' /etc/opkg/distfeeds.conf
opkg update

echo "step: install common softwares"
opkg install curl rsync || exit $?

if [ "$OPENWRT_IS_SNAPSHOT" = "true" ];then
	opkg install luci
fi

echo "step: enable https for uhttpd"
opkg install luci-ssl-openssl libuhttpd-openssl || exit $?
/etc/init.d/uhttpd reload
