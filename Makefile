#
# Copyright 2020 Xingwang Liao <kuoruan@gmail.com>
# Licensed to the public under the MIT License.
# Refactored for OpenWrt (Firewall4 / nftables) Architecture
#

include $(TOPDIR)/rules.mk

PKG_NAME:=luci-app-tp
PKG_VERSION:=2.2.2
PKG_RELEASE:=2

PKG_LICENSE:=MIT
PKG_MAINTAINER:=Xingwang Liao <kuoruan@gmail.com>

LUCI_TITLE:=LuCI support for tp (V2Ray / Xray)

# 纯正的 Nftables 架构依赖栈：TProxy, Socket 匹配及 JSON 解析器
LUCI_DEPENDS:=+jshn +ip +nftables-json +kmod-nft-socket +kmod-nft-tproxy \
	+resolveip +dnsmasq-full
LUCI_PKGARCH:=all

# 注册核心配置与路由表，防止系统升级或重新安装时被覆盖
define Package/$(PKG_NAME)/conffiles
/etc/config/v2ray
/etc/v2ray/config.json
/etc/v2ray/directlist.txt
/etc/v2ray/proxylist.txt
/etc/v2ray/gfwlist.txt
/etc/v2ray/srcdirectlist.txt
endef

include $(TOPDIR)/feeds/luci/luci.mk

# ==============================================================================
# 安装后执行动作 (Post-Install)
# ==============================================================================
define Package/$(PKG_NAME)/postinst
#!/bin/sh

# 区分构建环境与真实路由器环境
if [ -z "$${IPKG_INSTROOT}" ] ; then
	
	# 1. 初始化基础 UCI 控制配置
	uci -q get v2ray.main >/dev/null || {
		uci set v2ray.main=v2ray
		uci set v2ray.main.enabled='0'
		uci commit v2ray
	}
fi

# 2. 严格赋权：确保守护脚本、及 RPCD 异步数据接口具备执行权限
chmod 755 "$${IPKG_INSTROOT}/etc/init.d/v2ray" >/dev/null 2>&1
chmod 755 "$${IPKG_INSTROOT}/usr/libexec/rpcd/luci.v2ray" >/dev/null 2>&1

# (可选保留) 如果你在 nftables 架构下依然保留了自愈钩子，确保其有权限
[ -f "$${IPKG_INSTROOT}/etc/firewall.v2ray" ] && chmod 755 "$${IPKG_INSTROOT}/etc/firewall.v2ray" >/dev/null 2>&1

# 3. 创建系统开机自启项 (兼容离线构建目录与在线真实环境)
if [ -z "$${IPKG_INSTROOT}" ] ; then
	/etc/init.d/v2ray enable
else
	ln -sf "../init.d/v2ray" "$${IPKG_INSTROOT}/etc/rc.d/S99v2ray" >/dev/null 2>&1
fi

exit 0
endef

# ==============================================================================
# 卸载后执行动作 (Post-Remove)
# ==============================================================================
define Package/$(PKG_NAME)/postrm
#!/bin/sh

# 仅在非构建环境 (即真实路由器系统) 中执行
if [ -z "$${IPKG_INSTROOT}" ] ; then
	
	# 1. 禁用开机自启
	/etc/init.d/v2ray disable

	# 2. 彻底清空 LuCI Web 界面渲染缓存，确保卸载后从左侧菜单树中消失
	rm -rf /tmp/luci-indexcache /tmp/luci-modulecache/
fi

exit 0
endef

# call BuildPackage - OpenWrt buildroot signature
