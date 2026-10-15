#!/bin/sh
#
# snmpd start script for Padavan rc
# Exposes the ARP table (ipNetToMediaTable) so upper-layer L3 discovery
# can read the real MAC of hosts behind this router.
#
# Manual debug: /usr/sbin/snmpd -c /etc_ro/snmp/snmpd.conf -f -Lo
#

SNMPD_BIN=/usr/sbin/snmpd
SNMPD_CONF=/etc_ro/snmp/snmpd.conf

start_snmpd() {
	[ -x "$SNMPD_BIN" ] || return 0
	# already running
	[ -n "$(pidof snmpd)" ] && return 0

	# minimal read-only config (community: public, port 161)
	[ -f "$SNMPD_CONF" ] || {
		mkdir -p /etc_ro/snmp
		cat > "$SNMPD_CONF" <<'EOF'
# net-snmp minimal read-only config
rocommunity  public default
view   all    included   .1
syslocation  Router
syscontact   admin@localhost
agentaddress udp:161
EOF
	}

	"$SNMPD_BIN" -c "$SNMPD_CONF" -Lo >/dev/null 2>&1 &
}

stop_snmpd() {
	[ -z "$(pidof snmpd)" ] && return 0
	killall snmpd 2>/dev/null
}

case "$1" in
	start)   start_snmpd ;;
	stop)    stop_snmpd ;;
	restart) stop_snmpd; sleep 1; start_snmpd ;;
	*)       echo "usage: $0 {start|stop|restart}"; exit 1 ;;
esac

exit 0