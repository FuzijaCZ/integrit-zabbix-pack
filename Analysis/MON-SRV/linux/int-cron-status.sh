#!/bin/sh
# Integrit MON-SRV: status of cron jobs recorded by int-cron-wrap (runs as user zabbix).
# Output: [{"job":"x","rc":0,"age":123,"duration":45}, ...]
STATE_DIR=/var/lib/int-cron
now=$(date +%s)
sep=''

printf '['
for f in "$STATE_DIR"/*.json; do
    [ -f "$f" ] || continue
    line=$(head -n 1 "$f")
    job=$(printf '%s' "$line" | sed -n 's/.*"job":"\([A-Za-z0-9._-]*\)".*/\1/p')
    rc=$(printf '%s' "$line" | sed -n 's/.*"rc":\([0-9]*\).*/\1/p')
    start=$(printf '%s' "$line" | sed -n 's/.*"start":\([0-9]*\).*/\1/p')
    end=$(printf '%s' "$line" | sed -n 's/.*"end":\([0-9]*\).*/\1/p')
    [ -n "$job" ] && [ -n "$rc" ] && [ -n "$start" ] && [ -n "$end" ] || continue
    printf '%s{"job":"%s","rc":%d,"age":%d,"duration":%d}' "$sep" "$job" "$rc" "$((now - end))" "$((end - start))"
    sep=','
done
printf ']\n'
