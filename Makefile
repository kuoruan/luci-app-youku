#
# Copyright (C) 2010-2011 OpenWrt.org
#
# This is free software, licensed under the GNU General Public License v2.
# See /LICENSE for more information.
#

include $(TOPDIR)/rules.mk

PKG_NAME:=luci-app-youku
PKG_RELEASE:=1.0

include $(INCLUDE_DIR)/package.mk

define Package/luci-app-youku
  SECTION:=LuCI
  CATEGORY:=LuCI
  SUBMENU:=3. Applications
  TITLE:=Luci Support for Youku acc.
  DEPENDS:=+luci +libstdcpp +libthread-db +librt +wget +curl
  PKGARCH:=all
endef

define Package/luci-app-youku/description
	Luci Support for Youku acc,only chinese.
endef

define Package/luci-app-youku/postinst
#!/bin/sh
[ -n "${IPKG_INSTROOT}" ] || {
	(. /etc/uci-defaults/luci-youku) && rm -f /etc/uci-defaults/luci-youku
	exit 0
}
endef

define Build/Compile
endef

define Package/luci-app-youku/install
	$(CP) ./files/* $(1)
endef

$(eval $(call BuildPackage,luci-app-youku))

