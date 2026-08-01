#
# Copyright 2020 Xingwang Liao <kuoruan@gmail.com>
# Licensed to the public under the MIT License.
# Refactored for OpenWrt 21.02 (Firewall3 / iptables) Architecture
#

include $(TOPDIR)/rules.mk

PKG_NAME:=luci-app-tp
PKG_VERSION:=2.2.2
PKG_RELEASE:=2

PKG_LICENSE:=MIT
PKG_MAINTAINER:=Xingwang Liao <kuoruan@gmail.com>

LUCI_TITLE:=LuCI support for tp (V2Ray / Xray)

# 完美契合 FW3 与 TProxy 高性能机制的精确依赖栈
LUCI_DEPENDS:=+jshn +ip +iptables +ip6tables +ipset +kmod-ipt-tproxy \
	+iptables-mod-tproxy +resolveip +dnsmasq-full
LUCI_PKGARCH:=all

# 注册用户配置文件，防止跨版本升级时被覆盖重置
define Package/$(PKG_NAME)/conffiles
/etc/config/v2ray
/etc/v2ray/config.json
/etc/v2ray/directlist.txt
/etc/v2ray/proxylist.txt
/etc/v2ray/gfwlist.txt
/etc/v2ray/srcdirectlist.txt
/etc/firewall.v2ray
endef

include $(TOPDIR)/feeds/luci/luci.mk

# ==============================================================================
# 安装后执行动作 (Post-Install)
# ==============================================================================
define Package/$(PKG_NAME)/postinst
#!/bin/sh

# [区分构建环境与真实路由器环境]
if [ -z "$${IPKG_INSTROOT}" ] ; then
	
	# 1. 初始化基础 UCI 控制配置
	uci -q get v2ray.main >/dev/null || {
		uci set v2ray.main=v2ray
		uci set v2ray.main.enabled='0'
		uci commit v2ray
	}

	# 2. 自动化注入：将自定义透明代理钩子挂载至原生防火墙 (fw3) 生命周期中
	uci -q get firewall.v2ray >/dev/null || {
		uci set firewall.v2ray=include
		uci set firewall.v2ray.type='script'
		uci set firewall.v2ray.path='/etc/firewall.v2ray'
		uci set firewall.v2ray.reload='1'
		uci commit firewall
	}
fi

# 3. 严格赋权：确保 init.d 守护脚本、防火墙钩子、及 RPCD 数据接口具备可执行权限
chmod 755 "$${IPKG_INSTROOT}/etc/init.d/v2ray" >/dev/null 2>&1
chmod 755 "$${IPKG_INSTROOT}/etc/firewall.v2ray" >/dev/null 2>&1
chmod 755 "$${IPKG_INSTROOT}/usr/libexec/rpcd/luci.v2ray" >/dev/null 2>&1

# 4. 创建系统开机自启项 (兼容离线构建目录与在线真实机器)
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

if [ -z "$${IPKG_INSTROOT}" ] ; then
	
	# 1. 禁用开机自启
	/etc/init.d/v2ray disable

	# 2. 安全清理：剥离防火墙自定义钩子，防止系统防火墙因找不到脚本而抛错
	uci -q delete firewall.v2ray
	uci commit firewall

	# 3. 彻底清空 LuCI Web 界面缓存，确保应用卸载后从菜单树中消失
	rm -rf /tmp/luci-indexcache /tmp/luci-modulecache/
fi

exit 0
endef

# call BuildPackage - OpenWrt buildroot signature
