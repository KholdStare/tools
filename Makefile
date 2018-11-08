THIS_DIR := $(realpath $(dir $(firstword $(MAKEFILE_LIST))))
SRC_DIR := $(THIS_DIR)/src

.PHONY: all
all: ccache_install vim_install tmux_install ninja_install ctags_install emacs_install fzf_install cgdb_install dbeaver_install rtags_install

INSTALL_PREFIX ?= $(THIS_DIR)
INSTALL_PREFIX := $(realpath $(INSTALL_PREFIX))

$(INSTALL_PREFIX):
	mkdir -p $(INSTALL_PREFIX)

.PHONY: submodules
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
	&& wget --no-check-certificate -O $(1).tar.$(3) $(2) \
	&& tar -xf $(1).tar.$(3) -C $(1) --strip-components 1 \
	&& rm $(1).tar.$(3)

GIT_CLONE_TEMPLATE = cd $(SRC_DIR) \
	&& git clone --recursive $(2) $(1) \
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
.PHONY: vim_install
vim_install: $(INSTALL_PREFIX)/bin/vim

# ======================
# fzf
#
$(HOME)/.fzf:
	git clone --depth 1 https://github.com/junegunn/fzf.git ~/.fzf \
	&& ~/.fzf/install
.PHONY: fzf_install
fzf_install: $(HOME)/.fzf

# ======================
# emacs
#
$(SRC_DIR)/emacs:
	$(call WGET_TEMPLATE,emacs,'http://reflection.oss.ou.edu/gnu/emacs/emacs-25.3.tar.gz',gz)
$(INSTALL_PREFIX)/bin/emacs: $(SRC_DIR)/emacs
	$(call CONFIG_MAKE_INSTALL_TEMPLATE,--with-gif=no)
.PHONY: emacs_install
emacs_install: $(INSTALL_PREFIX)/bin/emacs

# ======================
# ctags
#
$(SRC_DIR)/ctags:
	$(call WGET_TEMPLATE,ctags,'https://downloads.sourceforge.net/project/ctags/ctags/5.8/ctags-5.8.tar.gz?r=https%3A%2F%2Fsourceforge.net%2Fprojects%2Fctags%2Ffiles%2Fctags%2F5.8%2F&ts=1510697695&use_mirror=pilotfiber',gz)
$(INSTALL_PREFIX)/bin/ctags: $(SRC_DIR)/ctags
	patch $</routines.c $(SRC_DIR)/ctags.patch
	$(call CONFIG_MAKE_INSTALL_TEMPLATE,)
.PHONY: ctags_install
ctags_install: $(INSTALL_PREFIX)/bin/ctags

# ======================
# libevent
#
$(SRC_DIR)/libevent:
	$(call WGET_TEMPLATE,libevent,'https://github.com/libevent/libevent/releases/download/release-2.1.8-stable/libevent-2.1.8-stable.tar.gz',gz)
$(INSTALL_PREFIX)/lib/libevent.so: $(SRC_DIR)/libevent
	$(call CONFIG_MAKE_INSTALL_TEMPLATE,)
.PHONY: libevent_install
libevent_install: $(INSTALL_PREFIX)/lib/libevent.so

# ======================
# Tmux
#
$(SRC_DIR)/tmux:
	$(call WGET_TEMPLATE,tmux,https://github.com/tmux/tmux/releases/download/2.6/tmux-2.6.tar.gz,gz)
$(INSTALL_PREFIX)/bin/tmux: $(SRC_DIR)/tmux libevent_install
	$(call CONFIG_MAKE_INSTALL_TEMPLATE,)
.PHONY: tmux_install
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
.PHONY: asciidoc_install
asciidoc_install: $(INSTALL_PREFIX)/bin/asciidoc

# ======================
# ccache
#
$(SRC_DIR)/ccache:
	$(call WGET_TEMPLATE,ccache,https://github.com/ccache/ccache/archive/v3.4.2.tar.gz,gz)
$(INSTALL_PREFIX)/bin/ccache: $(SRC_DIR)/ccache $(INSTALL_PREFIX)/bin/asciidoc
	cd $< \
		&& ./autogen.sh \
		&& PKG_CONFIG_PATH=$(INSTALL_PREFIX)/lib/pkgconfig CFLAGS=-Wimplicit-fallthrough=0 ./configure --prefix=$(INSTALL_PREFIX) $(1) \
		&& make -j 20 \
		&& make MANPAGE_XSL=$(INSTALL_PREFIX)/etc/asciidoc/docbook-xsl/manpage.xsl install
.PHONY: ccache_install
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
.PHONY: ninja_install
ninja_install: $(INSTALL_PREFIX)/bin/ninja

# ======================
# Texinfo
#
$(SRC_DIR)/texinfo:
	$(call WGET_TEMPLATE,texinfo,http://ftp.gnu.org/gnu/texinfo/texinfo-6.5.tar.xz,xz)
$(INSTALL_PREFIX)/bin/makeinfo: $(SRC_DIR)/texinfo
	$(call CONFIG_MAKE_INSTALL_TEMPLATE,)
.PHONY: texinfo_install
texinfo_install: $(INSTALL_PREFIX)/bin/makeinfo


# ======================
# CGDB
#
$(SRC_DIR)/cgdb:
	$(call WGET_TEMPLATE,cgdb,https://cgdb.me/files/cgdb-0.7.0.tar.gz,gz)
$(INSTALL_PREFIX)/bin/cgdb: $(SRC_DIR)/cgdb $(INSTALL_PREFIX)/bin/makeinfo
	$(call CONFIG_MAKE_INSTALL_TEMPLATE,)
.PHONY: cgdb_install
cgdb_install: $(INSTALL_PREFIX)/bin/cgdb

# ======================
# rtags
#

$(SRC_DIR)/rtags:
	cd $(SRC_DIR) \
		&& git clone --recursive https://github.com/Andersbakken/rtags.git
$(INSTALL_PREFIX)/bin/rdm: $(SRC_DIR)/rtags $(INSTALL_PREFIX)/bin/emacs
	cd $< \
		&& mkdir -p build \
		&& cd build \
		&& rm -rf CMakeCache.txt CMakeFiles \
		&& CC=$(shell which gcc) CXX=$(shell which g++) cmake -G Ninja -DCMAKE_BUILD_TYPE=Release .. \
		&& ninja \
		&& cmake -DCMAKE_INSTALL_PREFIX=$(INSTALL_PREFIX) -P cmake_install.cmake
.PHONY: rtags_install
rtags_install: $(INSTALL_PREFIX)/bin/rdm


# ======================
# Ag
#
$(SRC_DIR)/the_silver_searcher: | submodules
.PHONY: ag_install
ag_install: $(INSTALL_PREFIX)/bin/ag

# sudo apt-get install -y automake pkg-config libpcre3-dev zlib1g-dev liblzma-dev
$(INSTALL_PREFIX)/bin/ag: $(SRC_DIR)/the_silver_searcher $(INSTALL_PREFIX)
	cd the_silver_searcher \
		&& ./build.sh --prefix=$(INSTALL_PREFIX) \
		&& $(MAKE) install


# ======================
# DBeaver
#
$(SRC_DIR)/dbeaver:
	$(call WGET_TEMPLATE,dbeaver,https://dbeaver.jkiss.org/files/dbeaver-ce-latest-linux.gtk.x86_64.tar.gz,gz)
.PHONY: dbeaver_install
$(INSTALL_PREFIX)/bin/dbeaver: $(SRC_DIR)/dbeaver
	ln -s $</dbeaver $@
dbeaver_install: $(INSTALL_PREFIX)/bin/dbeaver

# ======================
# Vertica Client drivers
#
$(INSTALL_PREFIX)/opt/vertica/java/lib/vertica-jdbc-8.1.1-7.jar:
	cd $(INSTALL_PREFIX) \
	&& wget --no-check-certificate -O vertica-client.tar.gz https://my.vertica.com/client_drivers/8.1.x/8.1.1-7/vertica-client-8.1.1-7.x86_64.tar.gz \
	&& tar -xf vertica-client.tar.gz \
	&& rm vertica-client.tar.gz
.PHONY: vertica_drivers_install
vertica_drivers_install: $(INSTALL_PREFIX)/opt/vertica/java/lib/vertica-jdbc-8.1.1-7.jar

# ======================
# jucipp
#
$(SRC_DIR)/jucipp:
	$(call GIT_CLONE_TEMPLATE,jucipp,https://github.com/cppit/jucipp.git,master)
$(INSTALL_PREFIX)/bin/jucipp: $(SRC_DIR)/jucipp
.PHONY: jucipp_install
jucipp_install: $(INSTALL_PREFIX)/bin/jucipp

