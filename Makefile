#
# Copyright (C) 2006-2017 OpenWrt.org
#
# This is free software, licensed under the GNU General Public License v2.
# See /LICENSE for more information.
#

include $(TOPDIR)/rules.mk
include $(CURDIR)/prebuilt.mk

PKG_NAME:=node
PKG_BASE:=packages-25.12
PKG_VERSION:=$(NODE_UPSTREAM_VERSION)
PKG_RELEASE:=$(NODE_PREBUILT_RELEASE)
PKG_BUILD_VERSION:=$(NODE_PREBUILT_VERSION)
PKG_MAJOR_VERSION:=v$(NODE_UPSTREAM_VERSION)

PKG_MAINTAINER:=Hirokazu MORIKAWA <morikw2@gmail.com>, Adrian Panella <ianchi74@outlook.com>
PKG_LICENSE:=MIT
PKG_LICENSE_FILES:=LICENSE
PKG_CPE_ID:=cpe:/a:nodejs:node.js

PKG_BUILD_DIR:=$(BUILD_DIR)/$(PKG_NAME)-$(PKG_BUILD_VERSION)
NODE_PREBUILT_DL_DIR:=$(DL_DIR)/$(PKG_NAME)-prebuilt/$(PKG_BASE)
NODE_PREBUILT_NODE_DIR:=$(PKG_BUILD_DIR)/node
NODE_PREBUILT_NPM_DIR:=$(PKG_BUILD_DIR)/node-npm
NODE_PREBUILT_NODE_ARCHIVE_DIR:=$(PKG_BUILD_DIR)/archive-node
NODE_PREBUILT_NPM_ARCHIVE_DIR:=$(PKG_BUILD_DIR)/archive-node-npm
NODE_PREBUILT_AUTO_FLAVOR:=lean
NODE_PREBUILT_AUTO_FORMAT:=ipk

ifneq ($(filter ImmortalWrt,$(VERSION_DIST) $(CONFIG_VERSION_DIST)),)
  NODE_PREBUILT_AUTO_FLAVOR:=immortalwrt
endif

ifneq ($(CONFIG_USE_APK),)
  NODE_PREBUILT_AUTO_FORMAT:=apk
endif

NODE_PREBUILT_RESOLVED_FLAVOR:=$(if $(filter auto,$(NODE_PREBUILT_FLAVOR)),$(NODE_PREBUILT_AUTO_FLAVOR),$(NODE_PREBUILT_FLAVOR))
NODE_PREBUILT_RESOLVED_FORMAT:=$(if $(filter auto,$(NODE_PREBUILT_FORMAT)),$(NODE_PREBUILT_AUTO_FORMAT),$(NODE_PREBUILT_FORMAT))
NODE_PREBUILT_NODE_FILE:=node_$(PKG_BUILD_VERSION)_$(ARCH_PACKAGES)_$(NODE_PREBUILT_RESOLVED_FLAVOR).$(NODE_PREBUILT_RESOLVED_FORMAT)
NODE_PREBUILT_NPM_FILE:=node-npm_$(PKG_BUILD_VERSION)_$(ARCH_PACKAGES)_$(NODE_PREBUILT_RESOLVED_FLAVOR).$(NODE_PREBUILT_RESOLVED_FORMAT)
NODE_PREBUILT_NODE_URL:=$(NODE_PREBUILT_BASE_URL)/$(NODE_PREBUILT_NODE_FILE)
NODE_PREBUILT_NPM_URL:=$(NODE_PREBUILT_BASE_URL)/$(NODE_PREBUILT_NPM_FILE)

include $(INCLUDE_DIR)/host-build.mk
include $(INCLUDE_DIR)/package.mk

define Package/node
  SECTION:=lang
  CATEGORY:=Languages
  SUBMENU:=Node.js
  TITLE:=Node.js is a platform built on Chrome's JavaScript runtime
  URL:=https://nodejs.org/
  DEPENDS:=@USE_MUSL @HAS_FPU @(i386||x86_64||arm||aarch64||mipsel) \
	   +libstdcpp +libopenssl +zlib +libnghttp2 +libuv \
	   +libcares +libatomic +NODEJS_ICU_SYSTEM:icu +NODEJS_ICU_SYSTEM:icu-full-data
endef

define Package/node/description
  Node.js® is a JavaScript runtime built on Chrome's V8 JavaScript engine. Node.js uses
  an event-driven, non-blocking I/O model that makes it lightweight and efficient. Node.js'
  package ecosystem, npm, is the largest ecosystem of open source libraries in the world.

  This packages-25.12 branch downloads user-managed prebuilt node packages from GitHub
  Releases instead of relying on OpenWrt official binary packages. Both lean and
  ImmortalWrt, as well as ipk and apk payloads, are supported.
endef

define Package/node-npm
  SECTION:=lang
  CATEGORY:=Languages
  SUBMENU:=Node.js
  TITLE:=NPM stands for Node Package Manager
  URL:=https://www.npmjs.com/
  DEPENDS:=+node
endef

define Package/node-npm/description
	NPM is the package manager for NodeJS
endef

ifeq ($(HOST_ARCH),x86_64)
	NODE_ARCH:=x64
endif

ifeq ($(HOST_ARCH),aarch64)
	NODE_ARCH:=arm64
endif

define NodePrebuilt/Fetch
	[ -f $(NODE_PREBUILT_DL_DIR)/$(1) ] || \
		curl -fL --retry 3 --retry-delay 2 --connect-timeout 20 \
			-o $(NODE_PREBUILT_DL_DIR)/$(1) $(2)
endef

define NodePrebuilt/Extract
	rm -rf $(2) $(3)
	$(INSTALL_DIR) $(2) $(3)
	if [ "$(NODE_PREBUILT_RESOLVED_FORMAT)" = "ipk" ]; then \
		cd $(3) && ar x $(1); \
		data_archive=""; \
		for candidate in data.tar.gz data.tar.xz data.tar.zst data.tar; do \
			if [ -f "$(3)/$$candidate" ]; then \
				data_archive="$$candidate"; \
				break; \
			fi; \
		done; \
		[ -n "$$data_archive" ]; \
		cd $(2) && $(TAR) -xf "$(3)/$$data_archive"; \
	else \
		$(TAR) -xf $(1) -C $(2); \
	fi
endef

define Host/Compile
	$(INSTALL_DIR) $(HOST_BUILD_DIR)
	rm -rf $(HOST_BUILD_DIR)/node-v*
	cd $(HOST_BUILD_DIR) && \
		curl -fL --retry 3 --retry-delay 2 --connect-timeout 20 \
			-O https://nodejs.org/dist/$(PKG_MAJOR_VERSION)/node-$(PKG_MAJOR_VERSION)-linux-$(NODE_ARCH).tar.xz && \
		$(TAR) -xf node-$(PKG_MAJOR_VERSION)-linux-$(NODE_ARCH).tar.xz
endef

define Build/Compile
	$(INSTALL_DIR) $(NODE_PREBUILT_DL_DIR)
	rm -rf $(NODE_PREBUILT_NODE_DIR) $(NODE_PREBUILT_NPM_DIR) \
		$(NODE_PREBUILT_NODE_ARCHIVE_DIR) $(NODE_PREBUILT_NPM_ARCHIVE_DIR)
	$(INSTALL_DIR) $(NODE_PREBUILT_NODE_DIR) $(NODE_PREBUILT_NPM_DIR) \
		$(NODE_PREBUILT_NODE_ARCHIVE_DIR) $(NODE_PREBUILT_NPM_ARCHIVE_DIR)
	echo "Using prebuilt node assets from $(NODE_PREBUILT_BASE_URL) for $(ARCH_PACKAGES)"
	echo "Resolved flavor=$(NODE_PREBUILT_RESOLVED_FLAVOR) format=$(NODE_PREBUILT_RESOLVED_FORMAT)"
	$(call NodePrebuilt/Fetch,$(NODE_PREBUILT_NODE_FILE),$(NODE_PREBUILT_NODE_URL))
	$(call NodePrebuilt/Fetch,$(NODE_PREBUILT_NPM_FILE),$(NODE_PREBUILT_NPM_URL))
	$(call NodePrebuilt/Extract,$(NODE_PREBUILT_DL_DIR)/$(NODE_PREBUILT_NODE_FILE),$(NODE_PREBUILT_NODE_DIR),$(NODE_PREBUILT_NODE_ARCHIVE_DIR))
	$(call NodePrebuilt/Extract,$(NODE_PREBUILT_DL_DIR)/$(NODE_PREBUILT_NPM_FILE),$(NODE_PREBUILT_NPM_DIR),$(NODE_PREBUILT_NPM_ARCHIVE_DIR))
endef

define Package/node/install
	$(INSTALL_DIR) $(1)/usr/bin
	$(INSTALL_BIN) $(NODE_PREBUILT_NODE_DIR)/usr/bin/node $(1)/usr/bin/
endef

define Package/node-npm/install
	$(INSTALL_DIR) $(1)/usr/lib/node_modules/npm
	$(CP) $(NODE_PREBUILT_NPM_DIR)/usr/lib/node_modules/npm/package.json $(1)/usr/lib/node_modules/npm/
	$(CP) $(NODE_PREBUILT_NPM_DIR)/usr/lib/node_modules/npm/LICENSE $(1)/usr/lib/node_modules/npm/
	$(CP) $(NODE_PREBUILT_NPM_DIR)/usr/lib/node_modules/npm/README.md $(1)/usr/lib/node_modules/npm/
	$(CP) $(NODE_PREBUILT_NPM_DIR)/usr/lib/node_modules/npm/node_modules $(1)/usr/lib/node_modules/npm/
	$(CP) $(NODE_PREBUILT_NPM_DIR)/usr/lib/node_modules/npm/bin $(1)/usr/lib/node_modules/npm/
	$(CP) $(NODE_PREBUILT_NPM_DIR)/usr/lib/node_modules/npm/lib $(1)/usr/lib/node_modules/npm/
	$(INSTALL_DIR) $(1)/usr/bin
	$(LN) ../lib/node_modules/npm/bin/npm-cli.js $(1)/usr/bin/npm
	$(LN) ../lib/node_modules/npm/bin/npx-cli.js $(1)/usr/bin/npx
endef

define Host/Install
	$(CP) $(HOST_BUILD_DIR)/node-$(PKG_MAJOR_VERSION)-linux-$(NODE_ARCH)/* $(STAGING_DIR_HOST)/
endef

$(eval $(call HostBuild))
$(eval $(call BuildPackage,node))
$(eval $(call BuildPackage,node-npm))
