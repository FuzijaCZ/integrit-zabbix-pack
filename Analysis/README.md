# Integrit Zabbix monitoring pack: index

Zabbix 7.0.31 LTS. One folder per service; each has the template YAML(s), any agent / proxy scripts and an `INSTALL.md`
(what the customer provides, import boxes, host setup, how to verify). Start every service with its `INSTALL.md`.

All templates are named `INT <SERVICE-ID> <technology>`, carry the tag `service=<SERVICE-ID>`, and never modify official templates
(they link them, or replace them where the official one is passive-only or collides on the same host).

## Suggested order for trying them

| Step | Service | Why first |
|---|---|---|
| 1 | `PLATFORM` | Monitoring of the monitoring: proxies down = customer site down, failed notifications, dead-man switch |
| 2 | `MON-SRV` | Base for most add-ons (SECEVT, ROLE, DB, AD, CERT, SHUTDOWN, CONT run next to it) |
| 3 | `MON-NET`, `MON-UPS`, `MON-BKP` | Core site checks |
| 4 | the rest, one by one | each is independent |

## Services

| Folder | Templates | Linked on | Collected by |
|---|---|---|---|
| `PLATFORM` | Zabbix server, Zabbix proxy (+ media type INT Heartbeat) | Zabbix server / proxy hosts | server, API |
| `MON-SRV` | Windows, Linux, SMART | servers | agent 2 active |
| `MON-BKP` | Veeam B&R, Veeam Agent, Windows Server Backup, E-mail reports, E-mail parser | VBR server, servers, report host | REST, event log, mail parser |
| `MON-UPS` | APC, Generic UPS-MIB, NUT | UPS | SNMP, agent |
| `MON-NET` | MikroTik, FortiGate, Generic SNMP, WAN, External, Site proxy, Meraki organization | gateways, WAN, site | SNMP, simple checks, API |
| `MON-LAN` | Switch base, Cisco IOS, HPE Aruba, MikroTik, Generic SNMP, UniFi Network | switches, UniFi controller | SNMP, API |
| `MON-NAS` | Synology DSM, QNAP | NAS | SNMP |
| `MON-VIRT` | VMware vSphere, Proxmox VE, Hyper-V | vCenter / ESXi, PVE, Hyper-V hosts | VMware collector, HTTP API, agent |
| `MON-M365` | Tenant | tenant host | Graph |
| `MON-EPS` | ESET PROTECT Cloud | tenant host | ESET Connect API |
| `MON-WEB-FUNC` | Scenario | web app host | Browser item |
| `MON-VOIP` | SIP endpoint | PBX / SBC | external script |
| `MON-CUSTOM` | Job, File, Log, Process, HTTP, TCP, Vendor status pages | any | agent, HTTP |
| `MON-HW` | Dell iDRAC, HPE iLO | BMC | SNMP, Redfish |
| `MON-DB` | MSSQL, MySQL, PostgreSQL | DB servers | agent 2 plugins |
| `MON-AD` | Domain controller, Service accounts | every DC | agent 2 + PowerShell |
| `MON-MAIL` | Basic, Plus, Exchange, Postfix | domain host, mail servers | external script, Graph, agent |
| `MON-ENV` | SNMP sensors, APC Rack PDU, PDU generic | sensor units, PDUs | SNMP |
| `MON-CERT` | Endpoints, Windows store, AD CS, Intune Apple | site probe host, servers, CA, tenant host | external script, agent, Graph |
| `MON-SECEVT` | Windows, Linux | member servers | agent 2 (event log, journal) |
| `MON-IDSEC` | Entra ID | tenant host | Graph |
| `MON-LIFECYCLE` | Asset, Renewals | any asset, per-customer renewals host | Script (macros) |
| `MON-EXPOSURE` | Public IP, KEV feed | per public IP, Zabbix server | external proxy + scan VM (nmap) |
| `MON-MDM` | Intune | tenant host | Graph |
| `MON-CLOUD` | Azure subscription, Azure VM, Azure SQL database, Azure backup vault, AWS account | per subscription / resource | Azure / AWS APIs (Lighthouse) |
| `MON-ROLE` | File server, DHCP, DNS, Print, RDS, IIS, Nginx, Apache, PHP-FPM | role servers | agent 2 + PowerShell, official web templates |
| `SRV-SHUTDOWN` | Windows agent, Linux NUT client, Plan | hosts with shutdown agents, UPS | agent |
| `MON-CCTV` | Hikvision NVR, Generic cameras, Hikvision camera | NVR, cameras | ISAPI, ICMP / RTSP |
| `MON-PRINT` | Printer | printers / MFPs | SNMP (Printer-MIB) |
| `MON-CONT` | Docker (Kubernetes: project notes) | Docker hosts | agent 2 Docker plugin |

Out of scope (done elsewhere): MON-WP, MON-DNS, MON-WEB basics.

## Common rules

- Import boxes are the same everywhere: Update existing / Create new **TICK**; Delete missing **UNTICKED** on the first import,
  **TICK** on updates for Items / Discovery rules / Triggers / Value maps; Template linkage → Delete missing always **UNTICKED**.
- Agents are active-only; scripts are read-only; Zabbix remote commands are never used.
- Every threshold is a macro: change it on the host (or with `{$MACRO:"context"}` per item), never in the template.
- Problems marked "close manually" in an INSTALL (security / change events) stay open until someone closes them after review.

## What was tested, and what is left for the first customer

Every template was imported and linked on a real Zabbix 7.0.31 (alone and in realistic stacks), and all JavaScript ran in the
server's own engine. Not run against real systems: PowerShell scripts (no Windows here), vendor APIs with real customer data (Graph,
ESET, UniFi, Azure, Hikvision ISAPI), SNMP OIDs of vendor MIBs (QNAP, APC PDU, sensor units). Results and the run sheet for the first
customer: [`PILOT.md`](PILOT.md).
