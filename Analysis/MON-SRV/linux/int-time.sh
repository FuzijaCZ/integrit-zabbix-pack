#!/bin/sh
# Integrit MON-SRV: time synchronisation for Zabbix agent 2 (runs as user zabbix).
# chrony first, then systemd-timesyncd. Offset in seconds, positive = local clock ahead.
# Output: {"synced":0|1,"offset":<float>|null}
LC_ALL=C
export LC_ALL

if command -v chronyc >/dev/null 2>&1 && out=$(chronyc -n tracking 2>/dev/null); then
    printf '%s\n' "$out" | awk -F': *' '
        /^System time/ { split($2, a, " "); off = a[1]; if ($2 ~ /slow/) off = -off }
        /^Leap status/ { synced = ($2 ~ /Not synchronised/) ? 0 : 1 }
        END { if (off == "") off = "null"; printf "{\"synced\":%d,\"offset\":%s}\n", synced, off }'
    exit 0
fi

if command -v timedatectl >/dev/null 2>&1; then
    synced=0
    [ "$(timedatectl show -p NTPSynchronized --value 2>/dev/null)" = "yes" ] && synced=1
    # "Offset: +1.234ms" (systemd 239+); units us, ms, s, min
    off=$(timedatectl timesync-status 2>/dev/null | awk '
        /Offset:/ {
            v = $2; m = 1
            if (v ~ /us$/) { m = 0.000001; sub(/us$/, "", v) }
            else if (v ~ /ms$/) { m = 0.001; sub(/ms$/, "", v) }
            else if (v ~ /min$/) { m = 60; sub(/min$/, "", v) }
            else if (v ~ /s$/) { sub(/s$/, "", v) }
            printf "%.6f", v * m
        }')
    printf '{"synced":%d,"offset":%s}\n' "$synced" "${off:-null}"
    exit 0
fi

echo '{"synced":0,"offset":null}'
