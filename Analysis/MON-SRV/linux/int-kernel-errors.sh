#!/bin/sh
# Integrit MON-SRV: kernel disk/filesystem/controller errors in the last 15 minutes.
# Runs as user zabbix, which must be in group systemd-journal (see INSTALL.md).
# Fails visibly (item becomes unsupported) instead of returning 0 when the journal is not readable.
LC_ALL=C
export LC_ALL

if ! journalctl -q -k -n 1 --no-pager >/dev/null 2>&1 || \
   journalctl -k -n 1 --no-pager 2>&1 | grep -q 'insufficient permissions'; then
    echo "int-kernel-errors.sh: journal not readable by $(id -un); add it to group systemd-journal" >&2
    exit 1
fi

journalctl -q -k -p err --since "15 min ago" --no-pager -o cat 2>/dev/null | \
    grep -ciE 'I/O error|blk_update_request|Buffer I/O error|critical medium error|medium error|unrecovered read error|EXT4-fs error|EXT4-fs \(.*\): (error|warning: mounting fs with errors)|XFS \(.*\): (corruption|metadata I/O error|log I/O error|Internal error)|BTRFS (error|critical)|Remounting filesystem read-only|nvme.*(timeout|reset|I/O.*error)|ata[0-9.]+: (exception|failed command|hard resetting link)|SCSI error|megaraid_sas.*(fault|reset)|mpt[0-9a-z]*sas.*(fault|reset)|hpsa.*(reset|failed)|aacraid.*(reset|failed)'
exit 0
