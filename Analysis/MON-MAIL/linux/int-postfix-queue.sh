#!/bin/sh
# Integrit MON-MAIL: Postfix queue sizes for Zabbix agent (runs as user zabbix, no root;
# postqueue is allowed for everyone by default: authorized_mailq_users = static:anyone).
# Needs Postfix 3.1+ (postqueue -j).
# Output: {"active":N,"deferred":N,"hold":N,"incoming":N,"total":N}
PATH=/usr/sbin:/usr/bin:/sbin:/bin
export PATH
out=$(postqueue -j 2>/dev/null) || { echo "int-postfix-queue.sh: postqueue -j failed" >&2; exit 1; }
printf '%s\n' "$out" | awk '
    match($0, /"queue_name": *"[a-z]+"/) {
        q = substr($0, RSTART, RLENGTH); sub(/.*"queue_name": *"/, "", q); sub(/"$/, "", q)
        n[q]++; total++
    }
    END {
        printf "{\"active\":%d,\"deferred\":%d,\"hold\":%d,\"incoming\":%d,\"total\":%d}\n",
            n["active"], n["deferred"], n["hold"], n["incoming"] + n["maildrop"], total
    }'
