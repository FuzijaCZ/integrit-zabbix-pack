# MON-LAN: switches, Wi-Fi and PoE: installation

Version 1.0 · Zabbix 7.0.31 · official templates `release/7.0` (commit 362508f). Draft reference: section 4.7.

## Which template

| Device | Template | Interface | Monitored by |
|---|---|---|---|
| Cisco Catalyst / IOS / IOS-XE switch | `INT MON-LAN Cisco IOS` | SNMP | site proxy |
| HPE Aruba / ProCurve (ArubaOS-Switch) | `INT MON-LAN HPE Aruba` | SNMP | site proxy |
| MikroTik CRS / CSS switch | `INT MON-LAN MikroTik` | SNMP | site proxy |
| UniFi switch, TP-Link, Netgear, Zyxel, D-Link, other | `INT MON-LAN Generic SNMP` | SNMP | site proxy |
| UniFi APs / switches / gateway (device online state, % APs offline) | `INT MON-LAN UniFi Network` (one host per UniFi site) | Agent interface = console IP (HTTPS target) | site proxy |
| Meraki MS / MR | `INT MON-NET Meraki organization` (MON-NET) | – | external proxy |

UniFi switches: use **both**. `INT MON-LAN Generic SNMP` on each switch gives ports, uplinks and PoE. `INT MON-LAN UniFi Network`
gives the online state of every adopted device and the APs.

Aruba CX switches (official `Aruba CX 8300s by SNMP`) and controller-based Wi-Fi other than UniFi / Meraki (Omada, Aruba Instant On)
are not in v1.0.

## Files

| File | Templates |
|---|---|
| `template_int_mon_lan_switches.yaml` | `INT MON-LAN Switch base` (vendor-neutral uplinks + PoE, linked by the wrappers) and the 4 vendor wrappers |
| `template_int_mon_lan_unifi.yaml` | `INT MON-LAN UniFi Network` |

## Port description convention (most of the deployment time)

Ports are monitored by **their description (ifAlias)**. Undescribed access ports never alert. This is how a desk PC being switched off
stays quiet.

| Prefix | Meaning | Monitored by | Link down |
|---|---|---|---|
| `UPL-` | uplink to core / firewall / other switch | INT switch base | **HIGH** |
| `LAG-` | member of a LAG / port-channel to another switch | INT switch base | **HIGH** |
| `CRIT-` | critical endpoint (e.g. printer of the reception, door system) | official template | AVERAGE |
| `SRV-` | server / NAS / hypervisor port | official template | AVERAGE |
| `AP-` | access point port | official template | AVERAGE |

Example: `UPL-CORE-SW01-Gi1/0/48`, `SRV-HV01-NIC1`, `AP-2NP-KITCHEN`. Set the descriptions during onboarding (switch CLI / web UI).
Override per host: `{$NET.IF.IFALIAS.MATCHES}` (official discovery) and `{$INT.LAN.UPLINK.IFALIAS.MATCHES}` (uplinks).

## Triggers

| Trigger | Severity | Default |
|---|---|---|
| Switch unavailable by ICMP (official) | HIGH | official |
| Uplink / LAG member down | HIGH | 2 checks |
| Critical / server / AP port link down (official) | AVERAGE | described ports only |
| Uplink utilisation | WARNING | > `{$INT.LAN.UPLINK.UTIL.MAX}`=90 % of port speed for 15 min |
| Uplink errors | WARNING | > 2 errors/s for 5 min (official error / bandwidth triggers on CRIT/SRV/AP ports as well) |
| PoE budget used | WARNING | > `{$INT.LAN.POE.BUDGET.MAX}`=90 % for 15 min |
| PoE port fault | AVERAGE | any port in fault for 2 checks |
| UniFi switch / gateway offline | HIGH | 10 min |
| UniFi AP offline | AVERAGE | 10 min |
| More than 30 % of UniFi APs offline | HIGH | `{$INT.UNIFI.AP.OFFLINE.MAX.PCT}` |
| UniFi API unreachable | AVERAGE | 15 min without data |

Spanning-tree topology changes (draft scope) are not alerted in v1.0. They are only useful with a known STP design per customer.

## 1. What the customer provides

- SNMPv3 read-only (authPriv) on every switch, allowed from the site proxy.
- Topology: which switch hangs on which uplink (for host dependencies).
- Permission to set port descriptions (or a port list so Integrit can set them).
- UniFi: a UniFi OS console with UniFi Network 9.0 or newer, an API key, and the site proxy allowed to reach the console on HTTPS 443.

## 2. Import

Import both YAML files (**Data collection → Templates → Import**). `template_int_mon_lan_switches.yaml` contains the base and the wrappers
together, and Zabbix imports them in the right order.

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

## 3. Configure hosts

**Switch:** host `<CUST>-<SITE>-SW01`, groups `Customers/<CUST>/<SITE>` + `Services/MON-LAN`, SNMPv3 interface, monitored by the site proxy,
the vendor wrapper template, tags `customer`, `site`, `managed`, `tier`, `contract`. Do not link `INT MON-LAN Switch base` on its own.

**UniFi:** host `<CUST>-<SITE>-UNIFI`, interface type Agent with the console IP (only used as HTTPS target `{HOST.CONN}`).
Get the API key and the site ID:

```bash
# UniFi Network → Settings → Control Plane → Integrations → Create API key
curl -sk -H "X-API-KEY: <key>" https://<console-ip>/proxy/network/integration/v1/sites
# → {"data":[{"id":"88f7af54-98f8-306a-a1c7-c9349722b1f6","name":"Default"}], ...}
```

Macros: `{$INT.UNIFI.API.KEY}` (secret) and `{$INT.UNIFI.SITE.ID}`.

**Dependencies (host level):** on an access switch, `Unavailable by ICMP ping` → depends on the uplink switch's
`INT: Uplink ... is down` or `Unavailable by ICMP ping`; the core switch → `INT: Site gateway is unreachable` (MON-NET). See MON-NET INSTALL step 4.

## 4. Verify

1. Switch: SNMP icon green; Latest data shows `INT: Uplink ...` items for each `UPL-`/`LAG-` port and official interface items **only**
   for `CRIT-`/`SRV-`/`AP-` ports (to speed it up, use *Execute now* on the SNMP walk item the discovery depends on).
2. PoE switch: `INT: PoE: Budget used` shows a %; non-PoE switch: no value (expected).
3. Unplug an uplink of a redundant LAG (agree with the customer): HIGH `INT: Uplink ... is down` within 2 min.
4. UniFi: `UniFi: Devices total` = number of adopted devices; one `UniFi [ap|switch|gateway] <name>: State` item per device = `ONLINE`.
   Unplug one AP: AVERAGE `INT: UniFi [ap] <name> is offline` after about 10 min.
