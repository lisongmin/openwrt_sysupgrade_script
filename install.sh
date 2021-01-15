#/usr/bin/env sh

_dir=$(dirname $0)

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

echo "step: enable https for uhttpd"
opkg install luci-ssl-openssl libuhttpd-openssl || exit $?
