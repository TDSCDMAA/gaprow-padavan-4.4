#
# net-snmp for Padavan (uClibc / mipsel)
#
# Purpose: provide snmpd exposing the ARP table (ipNetToMediaTable, 1.3.6.1.2.1.4.22)
#          so that an upper-layer (iKuai Q3000) "SNMP layer-3 discovery" can read
#          the REAL MAC of hosts behind this router.
#
# Modeled after trunk/libs/libssl and trunk/user/minidlna:
#   - SRC_NAME + download_test/extract_test/config_test/configure/clean/romfs
#   - configure uses --host/--build for cross compilation
#   - romfs stage installs into the target rootfs via $(ROMFSINST)
#

SRC_NAME = net-snmp-5.9.4
# SourceForge redirects to a mirror; wget follows it.
SRC_URL  = https://sourceforge.net/projects/net-snmp/files/net-snmp/5.9.4/$(SRC_NAME).tar.gz/download

THISDIR  = $(shell pwd)

#
# ==== cross compile options ====
#  1) net-snmp configure probes many system capabilities; cross compiling requires
#     explicit --host / --build, otherwise results are for the x86 host and linking fails.
#  2) Known uClibc issues:
#     - disable embedded perl / perl modules / python (host tooling, unstable in CI)
#     - disable kmem usage and other Linux-only probes
#     - preset ac_cv_* for capabilities that cannot be probed
#  3) Size control: keep only snmpd, no manuals, no trapd.
#
# pcre.h is needed by net-snmp (include/net-snmp/data_access/interface.h,
# agent/mibgroup/hardware/fsys/hw_fsys.h). Padavan builds libpcre but the header
# may not be present in $(STAGEDIR)/include at net-snmp build time, so we add the
# libpcre source dir to the include path as a fallback.
PCRE_SRCDIR = $(ROOTDIR)/libs/libpcre/pcre-8.43

NETSNMP_CFLAGS  = -Os -ffunction-sections -fdata-sections -D_GNU_SOURCE
NETSNMP_CFLAGS += -I$(STAGEDIR)/include
NETSNMP_CFLAGS += -I$(PCRE_SRCDIR)
NETSNMP_LDFLAGS = -Wl,--gc-sections
NETSNMP_LDFLAGS += -L$(STAGEDIR)/lib

# Pre-answered configure cache entries to avoid un-probeable checks
#
# IMPORTANT: force HAVE_PCRE_H off. configure probes the *host* /usr/include
# and reports "checking for pcre.h... yes", which makes net-snmp generate
# "#define HAVE_PCRE_H 1". But the cross toolchain (mipsel-linux-uclibc-gcc)
# then cannot find <pcre.h> when compiling data_access/interface.h and
# hardware/fsys/hw_fsys.h -> "fatal error: pcre.h: No such file or directory".
# net-snmp guards all pcre usage with "#if defined(HAVE_PCRE_H)" and falls back
# to POSIX regex, so disabling it is safe for a router agent.
NETSNMP_CACHE = \
	ac_cv_header_pcre_h=no \
	ac_cv_header_regex_h=yes \
	ac_cv_ETC_MNTTAB=/etc/mtab \
	ac_cv_etype=int \
	ac_cv_have_struct_sockaddr_storage=yes \
	ac_cv_have_ss_family=yes \
	ac_cv_func_getaddrinfo=yes \
	ac_cv_func_gethostbyname=yes

all: download_test extract_test config_test
	$(MAKE) -j$(HOST_NCPU) -C $(SRC_NAME)

download_test:
	( if [ ! -f $(SRC_NAME).tar.gz ]; then \
		wget -t5 --timeout=30 --no-check-certificate -O $(SRC_NAME).tar.gz $(SRC_URL); \
	fi )

extract_test:
	( if [ ! -d $(SRC_NAME) ]; then \
		tar -xzf $(SRC_NAME).tar.gz; \
	fi )

config_test:
	( if [ -f ./config_done ]; then \
		echo "the same configuration"; \
	else \
		make configure && touch config_done; \
	fi )

configure:
	( cd $(SRC_NAME) ; \
	$(NETSNMP_CACHE) \
	CFLAGS="$(NETSNMP_CFLAGS)" LDFLAGS="$(NETSNMP_LDFLAGS)" \
	./configure \
		--prefix=/usr \
		--host=$(HOST_TARGET) \
		--build=$(HOST_BUILD) \
		--with-defaults \
		--disable-embedded-perl \
		--without-perl-modules \
		--without-python \
		--disable-manuals \
		--disable-ucd-snmp-compatibility \
		--disable-shared \
		--enable-static \
		--with-mib-modules="mibII/ip mibII/at" \
		--with-out-mib-modules="host" \
		--without-openssl \
		--without-libwrap \
		--without-kmem-usage \
		--without-dmalloc \
		--without-efence \
		--without-rsaref \
		--with-logfile=/var/log/snmpd.log \
		--with-persistent-directory=/etc/storage/snmp \
		; \
	)

clean:
	if [ -f $(SRC_NAME)/Makefile ] ; then \
		$(MAKE) -C $(SRC_NAME) distclean ; \
	fi ; \
	rm -f config_done

romfs:
	$(ROMFSINST) -p +x $(THISDIR)/$(SRC_NAME)/agent/snmpd /usr/sbin/snmpd
	$(ROMFSINST) -p +x $(THISDIR)/snmpd.sh /usr/bin/snmpd.sh