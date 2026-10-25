# MON-NET: firewall, router, VPN and internet: installation

Version 1.0 · Zabbix 7.0.31 · official templates `release/7.0` (commit 362508f). Draft reference: sections 4.6 and 3.2.4.

MON-NET is the **root of every site**: other hosts of the site depend on the gateway. Build it before or together with
the other services of a site.

## Hosts per site

| Host | Template | Monitored by | Interface |
|---|---|---|---|
| `<CUST>-<SITE>-GW01` (main gateway / firewall) | `INT MON-NET MikroTik` / `INT MON-NET FortiGate` / `INT MON-NET Generic SNMP` (UniFi gateway, other) | site proxy | SNMP (+ HTTPS admin port for FortiGate licences) |
| `<CUST>-<SITE>-WAN` | `INT MON-NET WAN` | site proxy | Agent, IP = primary provider gateway (ping target only) |
| `<CUST>-<SITE>-EXT` | `INT MON-NET External` | external proxy group | Agent, IP = primary public IP of the site (ping target only) |
| `PXY-<CUST>-<SITE>` | `INT MON-NET Site proxy` | **server** (no proxy), group `Integrit/Platform` | none needed |
| `<CUST>-MERAKI` (Meraki customers, one per organization) | `INT MON-NET Meraki organization` | external proxy group | none |

## Files

| File | Templates |
|---|---|
| `template_int_mon_net_devices.yaml` | `INT MON-NET MikroTik` (links `Mikrotik by SNMP`), `INT MON-NET FortiGate` (links `FortiGate by SNMP`), `INT MON-NET Generic SNMP` (links `Network Generic Device by SNMP`) |
| `template_int_mon_net_site.yaml` | `INT MON-NET WAN`, `INT MON-NET External`, `INT MON-NET Site proxy` |
| `template_int_mon_net_meraki.yaml` | `INT MON-NET Meraki organization` (links `Cisco Meraki organization by HTTP`) |

## Triggers

| Trigger | Severity | Default |
|---|---|---|
| Site is unreachable from the internet (all public IPs) | DISASTER | 3 failed pings from the external proxy |
| Site gateway is unreachable (`{$INT.SITE.GATEWAY}`=1) | DISASTER | 3 failed pings from the site proxy (official HIGH "Unavailable by ICMP ping" fires too) |
| Monitoring proxy not seen | HIGH | `{$INT.PROXY.LASTSEEN.MAX}`=3m (Integrit internal) |
| WAN link down (provider gateway) | HIGH | 3 failed pings per link |
| Internet unreachable from the site (3 targets) | HIGH | 1.1.1.1, 8.8.8.8, 9.9.9.9 |
| Site is running on the backup WAN link | HIGH | public IP seen from inside ≠ `{$INT.WAN.PRIMARY.IP.MATCHES}`; resolves on return |
| Primary / backup public IP unreachable from internet | HIGH | depend on "site unreachable" |
| VPN tunnel down (site-to-site) | HIGH | 3 failed pings to the host behind the tunnel |
| FortiGate HA cluster degraded / member out of sync | HIGH | members < 2 / unsynced 15 min |
| Packet loss (per link, internet, from outside) | AVERAGE | > 5 % for 10 min |
| Latency > 3× 7-day baseline | WARNING | and > 50 ms |
| FortiGate licence expires / Meraki licence expires | WARNING | < 30 days |
| Meraki device offline (MX / other) / alerting | HIGH / AVERAGE / WARNING | 10 min |
| Official vendor triggers | as official | CPU, memory, temperature, interface link down / errors / bandwidth, SD-WAN health, IPsec tunnel (FortiGate), LTE signal (MikroTik) |

**Interface utilisation against the contracted speed** (draft: > 90 % of contract for 15 min, WARNING): the official
"High bandwidth usage" compares with the port speed. On the gateway set `{$IF.UTIL.MAX:"<WAN interface name>"}` to
90 % of the contract expressed in % of the port speed, e.g. 100 Mbit/s contract on a 1 Gbit/s port: `{$IF.UTIL.MAX:"ether1"}=9`.

**Not in v1.0** (draft optional): syslog analysis (failed admin logins, config change) and SNMP traps. Both need per-device
log routing on the proxy; they will follow once the pilot shows which events matter. Second external measuring point:
Zabbix 7.0 cannot combine two proxies in one trigger; the single external check plus the inside view is used instead.

## 1. What the customer provides

- Read-only SNMPv3 (authPriv, SHA/AES) on the gateway, allowed from the site proxy IP.
- List of WAN links: provider, contracted speed, **provider gateway IP**, public IP(s); which one is primary.
- ICMP echo allowed on the public IP(s) from the Integrit external proxy IPs.
- Site-to-site VPN tunnels with one always-on IP behind each tunnel (e.g. the remote DC or router LAN IP).
- FortiGate: REST API admin with a read-only profile, trusted host = site proxy IP → API token.
- Meraki: Dashboard API key of a read-only org admin, organization ID.
- Definition of "outage" vs "degradation" (catalog requirement): defaults above, adjust per site via macros.

## 2. Import

**Data collection → Templates → Import**, each YAML:

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

Common for customer hosts: groups `Customers/<CUST>/<SITE>` + `Services/MON-NET`; tags `customer`, `site`, `managed`, `tier`, `contract`.

**Gateway** `<CUST>-<SITE>-GW01`: SNMPv3 interface; template by vendor; macro `{$INT.SITE.GATEWAY}=1`.
- MikroTik: `/snmp community` disabled, `/snmp set enabled=yes` + v3 user via `/snmp community add name=zabbix security=private authentication-protocol=SHA1 encryption-protocol=AES ...` with `addresses=<proxy IP>`.
- FortiGate: also `{$FGATE.API.TOKEN}` (secret) and `{$FGATE.API.PORT}` if the admin port is not 443.
- UniFi gateway: enable SNMP in UniFi Network → Settings → System → SNMP (v3 where offered).

**WAN** `<CUST>-<SITE>-WAN`: Agent interface = primary provider gateway IP. Macros:

| Macro | Example |
|---|---|
| `{$INT.WAN.LINKS}` | `O2-FIBER:82.100.1.1;T-LTE:10.64.64.64` |
| `{$INT.WAN.PRIMARY.IP.MATCHES}` | `^82\.100\.1\.10$` |
| `{$INT.VPN.TUNNELS}` | `BRNO:10.20.0.1;AZURE:10.50.0.4` |
| `{$INT.WAN.LOSS.MAX:"T-LTE"}` | `10` (LTE is noisier) |

FortiGate sites: the official template already alerts on IPsec tunnels (AVERAGE). Either list the tunnels in `{$INT.VPN.TUNNELS}` (HIGH)
and set `{$VPN.STATE.CONTROL}=0` on the gateway, or leave `{$INT.VPN.TUNNELS}` empty and keep the official AVERAGE.

**External** `<CUST>-<SITE>-EXT`: monitored by the external proxy group; Agent interface = primary public IP.
Optional: `{$INT.WAN.BACKUP.PUBLIC.IP}` = backup link public IP and `{$INT.WAN.BACKUP.CHECK}=1`.

**Site proxy** `PXY-<CUST>-<SITE>`: host name **exactly** the proxy name; group `Integrit/Platform`; monitored by server.

**Meraki** `<CUST>-MERAKI`: monitored by the external proxy group; macros `{$MERAKI.TOKEN}` (secret) and `{$ORGANIZATION_ID}`.

## 4. Dependencies (host level, once per site)

Templates cannot point at another host, so set these on the hosts (Data collection → Hosts → host → Triggers → open trigger → **Dependencies** → Add):

| Trigger on | Depends on |
|---|---|
| Every other host of the site: its availability trigger (MON-SRV `Active checks are not available`, SNMP devices `Unavailable by ICMP ping` / `No SNMP data collection`) | `<CUST>-<SITE>-GW01`: `INT: Site gateway is unreachable` |
| `PXY-<CUST>-<SITE>`: `INT: Monitoring proxy ... not seen` | `<CUST>-<SITE>-EXT`: `INT: Site is unreachable from the internet` |
| `<CUST>-<SITE>-WAN`: `INT: Internet is unreachable from the site` | `<CUST>-<SITE>-GW01`: `INT: Site gateway is unreachable` |

Verify on the first pilot site that Zabbix 7.0.31 accepts host-level dependencies on these templated triggers. If it does not,
the onboarding tool (draft 3.1.5) must create them through the API.

## 5. Verify

1. Gateway: SNMP icon green; Latest data shows interfaces, CPU, memory; `ICMP ping` = 1.
2. WAN: one `WAN [<link>]: Provider gateway ping` per link within 1 h (discovery) = 1; `Public IP seen from inside` = the primary public IP.
3. EXT: `Primary WAN public IP ping` = 1 (if 0, ICMP is blocked on the customer firewall).
4. Proxy host: `Proxy last seen` updates every few seconds.
5. Failover test (with the customer): unplug the primary WAN. Expect `INT: WAN [<primary>] is down` (HIGH) and
   `INT: Site is running on the backup WAN link` (HIGH) within 5 min. Reconnect: both resolve.
6. Without a test window: set `{$INT.WAN.PRIMARY.IP.MATCHES}` to `^0\.0\.0\.0$` → backup-link problem within 5 min; revert.
