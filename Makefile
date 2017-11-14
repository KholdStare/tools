THIS_DIR := $(realpath $(dir $(firstword $(MAKEFILE_LIST))))
SRC_DIR := $(THIS_DIR)/src

.PHONY: \
	submodules \
	ag_install \
	tmux_install \
	libevent_install \
	ninja_install \
	ccache_install \
	asciidoc_install \
	ctags_install \

all: ccache_install vim_install tmux_install ninja_install ctags_install

INSTALL_PREFIX ?= $(THIS_DIR)
INSTALL_PREFIX := $(realpath $(INSTALL_PREFIX))

$(INSTALL_PREFIX):
	mkdir -p $(INSTALL_PREFIX)

submodules: .gitmodules
	git submodule update --init --recursive

# WTF? why doesn't this work?
# define WGET_SOURCE =
# $(SRC_DIR)/$(1):
# 	cd $(SRC_DIR) \
# 		&& mkdir $(1) \
# 		&& wget $(2) \
# 		&& tar -xf $(1)*.tar.gz -C $(1) --strip-components 1 \
# 		&& rm $(1)*.tar.gz
# endef

WGET_TEMPLATE = cd $(SRC_DIR) \
	&& mkdir $(1) \
	&& wget -O $(1).tar.gz $(2) \
	&& tar -xf $(1).tar.gz -C $(1) --strip-components 1 \
	&& rm $(1).tar.gz

GIT_CLONE_TEMPLATE = cd $(SRC_DIR) \
	&& git clone $(2) $(1) \
	&& cd $(1) \
    && git checkout $(3)

CONFIG_MAKE_INSTALL_TEMPLATE = cd $< \
	&& PKG_CONFIG_PATH=$(INSTALL_PREFIX)/lib/pkgconfig ./configure --prefix=$(INSTALL_PREFIX) $(1) \
	&& make -j 20 \
	&& make install

# ======================
# vim
#
$(SRC_DIR)/vim:
	$(call GIT_CLONE_TEMPLATE,vim,https://github.com/vim/vim.git,master)
$(INSTALL_PREFIX)/bin/vim: $(SRC_DIR)/vim
	$(call CONFIG_MAKE_INSTALL_TEMPLATE,--with-features=huge)
vim_install: $(INSTALL_PREFIX)/bin/vim

# ======================
# ctags
#
$(SRC_DIR)/ctags:
	$(call WGET_TEMPLATE,ctags,'https://downloads.sourceforge.net/project/ctags/ctags/5.8/ctags-5.8.tar.gz?r=https%3A%2F%2Fsourceforge.net%2Fprojects%2Fctags%2Ffiles%2Fctags%2F5.8%2F&ts=1510697695&use_mirror=pilotfiber')
$(INSTALL_PREFIX)/bin/ctags: $(SRC_DIR)/ctags
	patch $</routines.c $(SRC_DIR)/ctags.patch
	$(call CONFIG_MAKE_INSTALL_TEMPLATE,)
ctags_install: $(INSTALL_PREFIX)/bin/ctags

# ======================
# libevent
#
$(SRC_DIR)/libevent:
	$(call WGET_TEMPLATE,libevent,'https://github.com/libevent/libevent/releases/download/release-2.1.8-stable/libevent-2.1.8-stable.tar.gz')
$(INSTALL_PREFIX)/lib/libevent.so: $(SRC_DIR)/libevent
	$(call CONFIG_MAKE_INSTALL_TEMPLATE,)
libevent_install: $(INSTALL_PREFIX)/lib/libevent.so

# ======================
# Tmux
#
$(SRC_DIR)/tmux:
	$(call WGET_TEMPLATE,tmux,https://github.com/tmux/tmux/releases/download/2.6/tmux-2.6.tar.gz)
$(INSTALL_PREFIX)/bin/tmux: $(SRC_DIR)/tmux libevent_install
	$(call CONFIG_MAKE_INSTALL_TEMPLATE,)
tmux_install: $(INSTALL_PREFIX)/bin/tmux

# ======================
# asciidoc
#
$(SRC_DIR)/asciidoc:
	$(call GIT_CLONE_TEMPLATE,asciidoc,https://github.com/asciidoc/asciidoc,8.6.9)
$(INSTALL_PREFIX)/bin/asciidoc: $(SRC_DIR)/asciidoc
	cd $< \
		&& autoconf \
		&& $(call CONFIG_MAKE_INSTALL_TEMPLATE,)
asciidoc_install: $(INSTALL_PREFIX)/bin/asciidoc

# ======================
# ccache
#
$(SRC_DIR)/ccache:
	$(call WGET_TEMPLATE,ccache,https://github.com/ccache/ccache/archive/v3.3.4.tar.gz)
$(INSTALL_PREFIX)/bin/ccache: $(SRC_DIR)/ccache $(INSTALL_PREFIX)/bin/asciidoc
	cd $< \
		&& ./autogen.sh \
		&& PKG_CONFIG_PATH=$(INSTALL_PREFIX)/lib/pkgconfig ./configure --prefix=$(INSTALL_PREFIX) $(1) \
		&& make -j 20 \
		&& make MANPAGE_XSL=$(INSTALL_PREFIX)/etc/asciidoc/docbook-xsl/manpage.xsl install
ccache_install: $(INSTALL_PREFIX)/bin/ccache

# ======================
# Ninja
#
$(SRC_DIR)/ninja:
	cd $(SRC_DIR) \
		&& git clone https://github.com/ninja-build/ninja.git \
		&& cd ninja \
		&& git checkout release
$(SRC_DIR)/ninja/ninja: $(SRC_DIR)/ninja
	cd $(SRC_DIR)/ninja \
		&& ./configure.py --bootstrap
$(INSTALL_PREFIX)/bin/ninja: $(SRC_DIR)/ninja/ninja
	cp $< $@
ninja_install: $(INSTALL_PREFIX)/bin/ninja

# ======================
# Ag
#
$(SRC_DIR)/the_silver_searcher: | submodules
ag_install: $(INSTALL_PREFIX)/bin/ag

# sudo apt-get install -y automake pkg-config libpcre3-dev zlib1g-dev liblzma-dev
$(INSTALL_PREFIX)/bin/ag: $(SRC_DIR)/the_silver_searcher $(INSTALL_PREFIX)
	cd the_silver_searcher \
		&& ./build.sh --prefix=$(INSTALL_PREFIX) \
		&& $(MAKE) install
