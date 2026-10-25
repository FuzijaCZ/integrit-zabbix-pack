# MON-HW: server hardware (out-of-band): installation

Version 1.0 · Zabbix 7.0.31 · official templates `release/7.0` (commit 362508f). Draft reference: section 5.6.1.

Hardware health of physical servers read from the management controller (BMC), independent of the operating system. It also covers hardware RAID
controllers, which MON-SRV cannot see. Sold as an add-on to MON-SRV for physical servers ("Server Plus", draft 5.2).

## Which template

| Server | Template | Interface | BMC account |
|---|---|---|---|
| Dell PowerEdge (iDRAC 7/8/9) | `INT MON-HW Dell iDRAC` (links official `Dell iDRAC by SNMP`) | SNMP (SNMPv3) | iDRAC SNMPv3 user, read-only |
| HPE ProLiant (iLO 4/5/6) | `INT MON-HW HPE iLO` (links official `HPE iLO by HTTP`, Redfish) | none (script item) | iLO user with only the **Login** privilege |

Lenovo XClarity / Fujitsu iRMC (generic Redfish template, draft) and IPMI-only BMCs are not in v1.0. They get built when the first customer needs them.

## Files

| File | Templates |
|---|---|
| `template_int_mon_hw.yaml` | `INT MON-HW Dell iDRAC`, `INT MON-HW HPE iLO` |

## Triggers (main ones; the rest as in the official templates)

| Trigger | Severity | Dell | HPE |
|---|---|---|---|
| Virtual disk / RAID volume failed | DISASTER (Dell) / HIGH (HPE) | INT (official switched off by macro) | official volume critical |
| Virtual disk degraded | HIGH (Dell) / WARNING (HPE) | INT | official volume warning |
| Physical disk failed / SMART / predicted failure | HIGH | official | official |
| RAID controller / cache battery not OK | AVERAGE / WARNING | official | official controller |
| Power supply failed | HIGH | INT (official switched off by macro) | official PSU critical |
| Fan failed | AVERAGE (Dell) / HIGH (HPE) | official | official |
| Temperature warning / critical (BMC thresholds) | WARNING / AVERAGE (Dell), WARNING / HIGH (HPE) | official | official |
| Memory DIMM not OK | AVERAGE | official | via system status |
| Overall system critical / unrecoverable | AVERAGE / HIGH | official | official system |
| BMC unreachable / API error | WARNING (Dell) / HIGH (HPE) | official | official |
| Firmware / BIOS changed, component replaced | INFO (report) | official | official |

Draft difference accepted: HPE's failed volume is HIGH (official), not DISASTER. Its triggers have no severity macros to remap them cleanly.

## 1. What the customer provides

- **The management port is connected** to a network the site proxy can reach (often it is not: check during onboarding; cabling = billable work).
  Keep BMCs in the management VLAN. Never expose them wider than the proxy.
- Reasonably current BMC firmware.
- Dell: iDRAC Express or better (SNMP and health work with Express). HPE: iLO Standard is enough for Redfish health.

## 2. Prepare the BMC

**Dell iDRAC 9:** iDRAC Settings → Services → SNMP Agent: enabled, protocol **SNMPv3**. Users → local user `zabbix`, privilege **Read Only**,
SNMPv3 enabled, authentication SHA, privacy AES. (iDRAC 8: Overview → iDRAC Settings → Network → SNMP / Users.)
**HPE iLO 5/6:** Administration → User Administration → new user `zabbix` with only the **Login** privilege.

## 3. Import

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

## 4. Host

A separate host per BMC: `<CUST>-<SITE>-<server>-BMC` (e.g. `ACME-PRG-SRV-HV01-BMC`), groups `Customers/<CUST>/<SITE>` + `Services/MON-HW`,
monitored by the site proxy, tags `customer`, `site`, `managed`, `tier`, `contract`.

- Dell: SNMP interface (iDRAC IP, SNMPv3, `zabbix`, authPriv, SHA/AES), template `INT MON-HW Dell iDRAC`.
- HPE: no interface, template `INT MON-HW HPE iLO`, macros `{$ILO.URL}` = `https://<ilo-ip>/`, `{$ILO.USER}` = `zabbix`,
  `{$ILO.PASSWORD}` (secret), and `{$HTTP.TLS.VERIFY:"HPE iLO"}` = `none` while the iLO uses its self-signed certificate.

**Dependencies:** BMC host availability → site gateway (MON-NET). Do **not** make the OS host (MON-SRV) depend on the BMC: they fail independently.
If MON-VIRT also shows the ESXi host red because of the same hardware fault, that is expected: the VMware item reports the host state and MON-HW
reports which part failed.

## 5. Verify

1. Dell: SNMP icon green; Latest data shows `Overall system health status`, one item set per physical disk, virtual disk (`INT: Virtual disk [...]: State` =
   Online) and PSU (`INT: Power supply [...]: Status` = OK).
2. HPE: `Get data` has no error; items per drive, volume, PSU, fan, sensor.
3. Test (agree with the customer): pull one redundant PSU cable → HIGH PSU failed within about 2 min (Dell INT / HPE official). Plug it back: resolves.
