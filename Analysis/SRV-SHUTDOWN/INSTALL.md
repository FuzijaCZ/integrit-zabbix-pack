# SRV-SHUTDOWN: controlled shutdown on power failure: installation

Version 1.0 · Zabbix 7.0.31. Draft reference: section 5.6.4.

A **service**, not monitoring: the shutdown is done by the vendor tools (APC PowerChute Network Shutdown, Eaton IPP / IPM, NUT
upsmon, Synology / QNAP UPS client, their VMware / Hyper-V integrations). Zabbix only checks that these agents run and are connected,
and that the annual test is done. Zabbix remote commands are **not** used for shutdown (the proxy is usually on the same UPS and the
WAN is down during an outage).

| Template | Linked on |
|---|---|
| `INT SRV-SHUTDOWN Windows agent` | every Windows host / VM running PowerChute or Eaton IPP (MON-SRV host) |
| `INT SRV-SHUTDOWN Linux NUT client` | every Linux host / Proxmox node shut down by NUT upsmon (MON-SRV host) |
| `INT SRV-SHUTDOWN Plan` | the UPS host (next to its MON-UPS template) |

## Files

| File | Where |
|---|---|
| `template_int_srv_shutdown.yaml` | Zabbix import |
| `linux/int_srv_shutdown.conf` | `/etc/zabbix/zabbix_agent2.d/int_srv_shutdown.conf` on NUT client hosts |

## Triggers

| Trigger | Severity | Default |
|---|---|---|
| Shutdown agent service not running | HIGH | 3 checks |
| Shutdown agent lost connection to the UPS (event log) | HIGH | until a "restored" event |
| NUT upsmon not running · UPS not reachable through NUT | HIGH | 3 checks |
| UPS runtime below shutdown threshold + margin (on mains) | AVERAGE | MON-UPS trigger, `{$INT.UPS.RUNTIME.MIN}` (step 4) |
| Annual shutdown test overdue · test date not set | WARNING · INFO | 365 days |

## 1. Design per environment (Integrit, with the customer)

1. **Order:** VMs (application → database → domain controllers last) → hypervisor hosts → storage / NAS → network stays on UPS.
2. **Timing:** start shutdown when runtime ≤ (total shutdown duration + 5 min margin), not at a fixed battery %. Measure the total
   shutdown duration in the first test.
3. **Who triggers whom:** one shutdown agent per hypervisor (vSphere: PowerChute / IPM on a VM or vCenter integration; Hyper-V:
   PowerChute / IPP on each host), NAS UPS client as network UPS slave, Linux / Proxmox NUT client (upsmon `SHUTDOWNCMD`).
4. Record the plan in the customer documentation and in the description of the UPS host.

## 2. Shutdown agent names (Windows)

On each host: `Get-Service | Where-Object { $_.DisplayName -match 'PowerChute|Eaton|IPP|IPM' } | Format-Table Name, DisplayName`.
Put the service name(s) into `{$INT.SHUT.SERVICES}` (`;` separated). Exclude them from the MON-SRV official discovery
(`{$SERVICE.NAME.NOT_MATCHES}`), the shutdown template watches them at HIGH.

Event log check: the template reads Application log events whose source matches `{$INT.SHUT.EVENT.SOURCE}` and whose text is about
the UPS link. After installing the agent, unplug the UPS network card once and check the item `Shutdown agent: UPS communication
events`; if the wording differs (language, version), adjust `{$INT.SHUT.COMM.REGEX}` / `{$INT.SHUT.COMMLOST.REGEX}` on the host.

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

## 4. Hosts

- Windows agent hosts: link `INT SRV-SHUTDOWN Windows agent`, set `{$INT.SHUT.SERVICES}`, group `Services/SRV-SHUTDOWN`.
- Linux NUT clients: copy `int_srv_shutdown.conf`, restart the agent, link `INT SRV-SHUTDOWN Linux NUT client`,
  `{$INT.SHUT.NUT.UPS}` = `ups@<NUT server IP>` (as in `/etc/nut/upsmon.conf`).
- UPS host: link `INT SRV-SHUTDOWN Plan`, `{$INT.SHUT.LAST.TEST}` = date of the last test (`YYYY-MM-DD`), and set the MON-UPS macro
  `{$INT.UPS.RUNTIME.MIN}` = shutdown start threshold + 5 min margin (same unit as the MON-UPS template: see MON-UPS INSTALL).

## 5. Annual test protocol (report)

1. Maintenance window agreed; Zabbix maintenance on the customer's hosts (with data collection).
2. Pull the UPS mains input (or use the UPS self-test "simulate power failure" if the vendor supports it).
3. Record the time of: on battery, shutdown start, each VM / host / NAS down, total. Compare with the runtime at that load.
4. Restore power; record boot order and the time until services are back (MON-SRV / MON-VIRT green).
5. Write findings (agents not connected, wrong order, too short runtime → battery replacement in MON-LIFECYCLE), set
   `{$INT.SHUT.LAST.TEST}`.

## 6. Verify

1. Windows: Latest data → `Shutdown agent service <name>: state` = Running; unplug the UPS network card for 2 min → HIGH
   "lost connection to the UPS"; plug back → resolves with the restore event.
2. Linux: `zabbix_agent2 -t 'int.shut.nut[ups@192.168.1.10]'` → `1`.
3. UPS host: `Shutdown plan: days since last test` shows the age.

Event texts of PowerChute / Eaton vary by version and language: verify step 6.1 on the first installation.
