#
# Copyright (C) 2010-2011 OpenWrt.org
#
# This is free software, licensed under the GNU General Public License v2.
# See /LICENSE for more information.
# http://blog.kuoruan.com/ kuoruan <kuoruan@gmail.com>
#

include $(TOPDIR)/rules.mk

PKG_NAME:=luci-app-youku
PKG_VERSION:=1.2.1
PKG_RELEASE:=1

include $(INCLUDE_DIR)/package.mk

define Package/luci-app-youku
  SECTION:=LuCI
  CATEGORY:=LuCI
  SUBMENU:=3. Applications
  TITLE:=Luci Support for Youku acc.
  DEPENDS:=+luci +luci-lib-jsonc +libstdcpp +libthread-db +librt +wget +curl
  PKGARCH:=all
endef

define Package/luci-app-youku/description
	Luci Support for Youku acc,only chinese.
endef

define Package/luci-app-youku/conffiles
/etc/config/youku
endef

define Package/luci-app-youku/postinst
#!/bin/sh
[ -n "${IPKG_INSTROOT}" ] || {
	(. /etc/uci-defaults/luci-youku) && rm -f /etc/uci-defaults/luci-youku
	exit 0
}
endef

define Package/luci-app-youku/prerm
#!/bin/sh
/etc/init.d/youku stop

uci delete ucitrack.@youku[-1] >/dev/null 2>&1
uci commit ucitrack

rm -f /tmp/luci-indexcache
exit 0
endef

define Build/Compile
endef

define Package/luci-app-youku/postrm
#!/bin/sh
rm -f /etc/config/youku
rm -rf /etc/youku/
endef

define Package/luci-app-youku/install
	$(CP) ./files/* $(1)
endef

$(eval $(call BuildPackage,luci-app-youku))

