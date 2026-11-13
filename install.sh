#!/bin/sh
# Install dropbear on VK Capsula via adb. Usage: ./install.sh [host:port] [pubkey]
set -e
cd "$(dirname "$0")"
DEV=${1:-10.0.0.227:5555}
PUB=${2:-$HOME/.ssh/id_ed25519.pub}
S="adb -s $DEV"
adb connect "$DEV" >/dev/null 2>&1 || true
sha256sum -c SHA256SUMS
$S push dropbearmulti /usr/sbin/dropbearmulti
$S push S50dropbear /etc/init.d/S50dropbear
$S push id /usr/bin/id
$S push "$PUB" /tmp/authorized_keys.new
$S shell '
set -e
chmod 755 /usr/sbin/dropbearmulti /etc/init.d/S50dropbear /usr/bin/id
for n in dropbear dropbearkey dbclient scp; do ln -sf dropbearmulti /usr/sbin/$n; done
mkdir -p /root/.ssh && chmod 700 /root/.ssh
touch /root/.ssh/authorized_keys
grep -qxFf /tmp/authorized_keys.new /root/.ssh/authorized_keys || cat /tmp/authorized_keys.new >> /root/.ssh/authorized_keys
chmod 600 /root/.ssh/authorized_keys; rm -f /tmp/authorized_keys.new
/etc/init.d/S50dropbear restart
sync
' </dev/null
