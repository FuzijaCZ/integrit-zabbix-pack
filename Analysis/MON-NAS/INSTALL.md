# MON-NAS: NAS and storage: installation

Version 1.0 · Zabbix 7.0.31. Draft reference: section 4.3.

Zabbix 7.0 has no official Synology or QNAP template, so both are Integrit templates on the vendor SNMP MIBs.
TrueNAS (official `TrueNAS CORE by SNMP`) and enterprise SAN (HPE MSA, NetApp, Pure, ...) are not wrapped in v1.0; wrap them when the first customer needs them.

## Files

| File | Template | Devices |
|---|---|---|
| `template_int_mon_nas_synology.yaml` | `INT MON-NAS Synology DSM` | DiskStation / RackStation, DSM 7.x |
| `template_int_mon_nas_qnap.yaml` | `INT MON-NAS QNAP` | QTS 4.5+ / QTS 5 / QuTS hero |

## Triggers

| Trigger | Severity | Synology | QNAP |
|---|---|---|---|
| Storage pool / volume degraded or crashed | DISASTER | raidStatus Degraded / Crashed | volume status text degraded / failed / not active |
| Rebuild / resync running | WARNING | raidStatus Repairing / RAID syncing | status text rebuilding / synchronizing |
| Disk failed | HIGH | diskStatus System partition failed / Crashed | HdStatus read/write error / invalid |
| Disk health critical / failing | HIGH | diskHealthStatus 3/4 | SMART text abnormal |
| Disk health warning | AVERAGE | diskHealthStatus 2 | SMART text warning |
| Volume used | AVERAGE / HIGH | > 85 % / > 95 % for 15 min | same |
| Volume full in < 14 days | AVERAGE | 7-day forecast, above 70 % used | same |
| Power supply / fan failed | HIGH | powerStatus, system & CPU fan | fan at 0 rpm (no PSU OID in NAS-MIB) |
| System failed | HIGH | systemStatus | – |
| System / disk temperature | AVERAGE | > 60 °C / > 55 °C for 15 min | same |
| Firmware update available | WARNING | DSM update pending ≥ 7 days | not in NAS-MIB |
| NAS unreachable | HIGH | no SNMP answer for 5 min | same |

Macros (override per host; context = volume name, e.g. `{$INT.NAS.VOLUME.PUSED.CRIT:"/volume2"}=98`):
`{$INT.NAS.VOLUME.PUSED.WARN}`=85, `{$INT.NAS.VOLUME.PUSED.CRIT}`=95, `{$INT.NAS.TIMELEFT.MIN}`=14d, `{$INT.NAS.TEMP.MAX}`=60,
`{$INT.NAS.DISK.TEMP.MAX}`=55, `{$INT.NAS.UPDATE.PENDING}`=7d.

SNMP traps for instant disk failure (draft) are not used in v1.0. Polling every minute raises the problem within 1–2 minutes.
Snapshot / replication jobs (Synology Snapshot Replication, Hyper Backup) are monitored by MON-BKP (e-mail reports).

**QNAP note:** NAS-MIB returns text, and the parsing was written against the MIB definitions, not a real device.
Check every item on the first QNAP (step 4). If volume or temperature items are unsupported, send the output of
`snmpwalk -v3 ... <nas> 1.3.6.1.4.1.24681.1.2.17.1` to Integrit so the regex can be adjusted.

## 1. What the customer provides

- Admin access once to enable SNMP (or Integrit does it), NAS reachable from the site proxy on UDP 161.
- Purpose of each volume (for the report and per-volume thresholds).
- Contact person for the device.

## 2. Enable SNMPv3 on the device

- **Synology:** Control Panel → Terminal & SNMP → SNMP → enable SNMP service, **disable SNMPv1/v2c**, enable **SNMPv3**:
  user `zabbix`, protocol SHA, password; privacy AES, password. Firewall (Control Panel → Security → Firewall): allow UDP 161 from the site proxy only.
- **QNAP:** Control Panel → Network & File Services → SNMP → enable, SNMP version **SNMPv3**, user `zabbix`, authentication HMAC-SHA,
  privacy AES. Allow UDP 161 from the site proxy only.

## 3. Import and host

Import the YAML files (**Data collection → Templates → Import**):

| Rule | Update existing | Create new | Delete missing |
|---|---|---|---|
| Template groups | TICK | TICK | UNTICKED |
| Templates | TICK | TICK | – |
| Template dashboards | TICK | TICK | UNTICKED |
| Template linkage | – | TICK | **UNTICKED** |
| Items | TICK | TICK | first import UNTICKED · updates TICK |
| Discovery rules | TICK | TICK | first import UNTICKED · updates TICK |
| Triggers | TICK | TICK | first import UNTICKED · updates TICK |
| Graphs | TICK | TICK | UNTICKED |
| Web scenarios | TICK | TICK | UNTICKED |
| Value maps | TICK | TICK | first import UNTICKED · updates TICK |

Host `<CUST>-<SITE>-NAS01`: groups `Customers/<CUST>/<SITE>` + `Services/MON-NAS`, monitored by the site proxy, SNMP interface
(SNMPv3, security name `zabbix`, authPriv, SHA / AES, passphrases), template `INT MON-NAS Synology DSM` or `INT MON-NAS QNAP`,
tags `customer`, `site`, `managed`, `tier`, `contract`. Host dependency: `INT: ... NAS is unreachable` → site gateway (MON-NET).

## 4. Verify

1. SNMP icon green. Latest data after the first hour of discovery (or *Execute now* on the walk items):
   - one `Disk <name>: Status` / `Health status` / `Temperature` per installed disk;
   - one `Pool <name>: Status` (Synology) per storage pool, `Normal`;
   - one `Volume <name>: Space used, in %` per volume, matching the % shown in DSM / QTS Storage Manager (±1 %).
2. Synology: `Synology: DSM update available` = `Up to date` or `Available`.
3. QNAP: disk temperatures are numbers (not unsupported), volume status shows `Ready`.
4. Test (no hardware action needed): set `{$INT.NAS.VOLUME.PUSED.WARN}` below the current usage → AVERAGE within 15 min; remove the macro.
