#!/bin/sh
# Integrit MON-SRV: pending updates for Zabbix agent 2 (runs as user zabbix, no root).
# Uses only local package metadata: apt lists / dnf cache are refreshed by the OS timers
# (apt-daily.timer / unattended-upgrades, dnf-makecache.timer).
# Output: {"total":N,"security":N,"reboot_required":0|1,"last_patch_days":N}
LC_ALL=C
export LC_ALL
now=$(date +%s)

if command -v apt-get >/dev/null 2>&1; then
    sim=$(apt-get -s -o Debug::NoLocking=1 dist-upgrade 2>/dev/null) || exit 1
    total=$(printf '%s\n' "$sim" | grep -c '^Inst ')
    security=$(printf '%s\n' "$sim" | grep '^Inst ' | grep -ci 'security')
    reboot=0
    [ -f /var/run/reboot-required ] && reboot=1
    last=$(stat -c %Y /var/lib/dpkg/status)
elif command -v dnf >/dev/null 2>&1; then
    total=$(dnf -q -C check-update 2>/dev/null | awk 'NF==3 && $1 ~ /\./' | wc -l)
    security=$(dnf -q -C updateinfo list --security 2>/dev/null | awk 'NF>=3 {print $3}' | sort -u | wc -l)
    newest=$(rpm -q --last kernel-core kernel 2>/dev/null | grep '^kernel' | head -n 1 | awk '{print $1}')
    reboot=0
    case "$newest" in
        ''|*"$(uname -r)") ;;
        *) reboot=1 ;;
    esac
    last=$(rpm -qa --qf '%{INSTALLTIME}\n' | sort -n | tail -n 1)
else
    echo "int-updates.sh: neither apt-get nor dnf found" >&2
    exit 1
fi

printf '{"total":%d,"security":%d,"reboot_required":%d,"last_patch_days":%d}\n' \
    "$total" "$security" "$reboot" "$(( (now - last) / 86400 ))"
