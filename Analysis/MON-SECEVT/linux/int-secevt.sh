#!/bin/sh
# Integrit MON-SECEVT: Linux security signals for Zabbix agent 2 (runs as user zabbix; needs group systemd-journal,
# or adm on systems that log to /var/log/auth.log or /var/log/secure).
# Usage: int-secevt.sh <minutes> <sudo-users,comma> <ssh-allowed-source-prefixes,comma>
#   e.g. int-secevt.sh 5 root,asmir 203.0.113.10,198.51.100.   (plain lists: no UnsafeUserParameters needed)
# Output: {"ssh_failed":N,"ssh_ips":"...","sudo_other":N,"sudo_users":"...","ssh_public":N,"ssh_public_from":"..."}
LC_ALL=C
export LC_ALL
min=${1:-5}
sudo_ok=${2:-root}
ssh_ok=${3:-}

if command -v journalctl >/dev/null 2>&1 && journalctl -q -n 1 >/dev/null 2>&1; then
    logs=$(journalctl -q --no-pager -o short --since "-${min}min" _COMM=sshd + _COMM=sshd-session + _COMM=sudo 2>/dev/null)
else
    since=$(date -d "-${min} min" '+%b %e %H:%M:%S')
    file=/var/log/auth.log
    [ -r /var/log/secure ] && file=/var/log/secure
    [ -r "$file" ] || { echo "int-secevt.sh: no journal access and $file not readable (add zabbix to group systemd-journal or adm)" >&2; exit 1; }
    logs=$(awk -v s="$since" 'substr($0, 1, 15) >= s' "$file")
fi

printf '%s\n' "$logs" | awk -v sudo_ok="$sudo_ok" -v ssh_ok="$ssh_ok" '
    function top(arr,   k, out, n, best, bk, i) {
        out = ""
        for (i = 0; i < 3; i++) {
            best = 0; bk = ""
            for (k in arr) if (arr[k] > best) { best = arr[k]; bk = k }
            if (bk == "") break
            out = out (out == "" ? "" : ", ") bk " (" best ")"
            delete arr[bk]
        }
        return out
    }
    function listed(v, list,   n, a, i) {
        n = split(list, a, ",")
        for (i = 1; i <= n; i++) if (a[i] != "" && v == a[i]) return 1
        return 0
    }
    function allowed_src(ip, list,   n, a, i) {
        n = split(list, a, ",")
        for (i = 1; i <= n; i++) if (a[i] != "" && index(ip, a[i]) == 1) return 1
        return 0
    }
    function private_ip(ip) {
        return ip ~ /^(10\.|127\.|192\.168\.|169\.254\.|172\.(1[6-9]|2[0-9]|3[01])\.|::1$|fe80:|fd)/
    }
    / sshd(-session)?\[[0-9]+\]: (Failed password|Invalid user|Failed publickey)/ {
        ip = $0; sub(/.* from /, "", ip); sub(/ .*/, "", ip)
        failed++; fips[ip]++
    }
    / sshd(-session)?\[[0-9]+\]: Accepted / {
        ip = $0; sub(/.* from /, "", ip); sub(/ .*/, "", ip)
        if (!private_ip(ip) && !allowed_src(ip, ssh_ok)) { pub++; pubs[ip]++ }
    }
    / sudo(\[[0-9]+\])?: / && /COMMAND=/ && /USER=root/ {
        u = $0; sub(/.* sudo(\[[0-9]+\])?: +/, "", u); sub(/ .*/, "", u)
        if (!listed(u, sudo_ok)) { other++; sus[u]++ }
    }
    END {
        printf "{\"ssh_failed\":%d,\"ssh_ips\":\"%s\",\"sudo_other\":%d,\"sudo_users\":\"%s\",\"ssh_public\":%d,\"ssh_public_from\":\"%s\"}\n",
            failed, top(fips), other, top(sus), pub, top(pubs)
    }'
