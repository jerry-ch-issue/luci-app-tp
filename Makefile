#
# Copyright 2020 Xingwang Liao <kuoruan@gmail.com>
# Licensed to the public under the MIT License.
#
include $(TOPDIR)/rules.mk

PKG_NAME:=luci-app-tp
PKG_VERSION:=2.2.2
PKG_RELEASE:=1

PKG_LICENSE:=MIT
PKG_MAINTAINER:=Xingwang Liao <kuoruan@gmail.com>

LUCI_TITLE:=LuCI support for tp (V2Ray)
LUCI_DEPENDS:=+jshn +ip +iptables +ip6tables +ipset +kmod-ipt-tproxy \
	+iptables-mod-tproxy +iptables-mod-socket +resolveip +dnsmasq-full +procd-ujail
LUCI_PKGARCH:=all

define Package/$(PKG_NAME)/conffiles
/etc/config/v2ray
/etc/v2ray/config.json
/etc/v2ray/directlist.txt
/etc/v2ray/proxylist.txt
/etc/v2ray/gfwlist.txt
/etc/v2ray/srcdirectlist.txt
endef

include $(TOPDIR)/feeds/luci/luci.mk

define Package/$(PKG_NAME)/postinst
#!/bin/sh

if [ -z "$${IPKG_INSTROOT}" ] ; then
	uci -q get v2ray.main >/dev/null || {
		uci set v2ray.main=v2ray
		uci set v2ray.main.enabled='0'
		uci commit v2ray
	}
fi

chmod 755 "$${IPKG_INSTROOT}/etc/init.d/v2ray" >/dev/null 2>&1
ln -sf "../init.d/v2ray" \
	"$${IPKG_INSTROOT}/etc/rc.d/S99v2ray" >/dev/null 2>&1

exit 0
endef

define Package/$(PKG_NAME)/postrm
#!/bin/sh

if [ -s "$${IPKG_INSTROOT}/etc/rc.d/S99v2ray" ] ; then
	mv -f "$${IPKG_INSTROOT}/etc/rc.d/S99v2ray.bak" "$${IPKG_INSTROOT}/etc/rc.d/S99v2ray"
fi

if [ -z "$${IPKG_INSTROOT}" ] ; then
	rm -rf /tmp/luci-indexcache /tmp/luci-modulecache/
fi

exit 0
endef

# call BuildPackage - OpenWrt buildroot signature
