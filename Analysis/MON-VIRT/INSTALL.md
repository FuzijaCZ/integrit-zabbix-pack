# MON-VIRT: virtualisation platform: installation

Version 1.0 · Zabbix 7.0.31 · official templates `release/7.0` (commit 362508f). Draft reference: section 4.2.

## Which template

| Platform | Template | Host | Collected by |
|---|---|---|---|
| VMware vSphere (vCenter or standalone ESXi) | `INT MON-VIRT VMware vSphere` | one host per vCenter, e.g. `ACME-PRG-VCENTER` (no interface) | site proxy, VMware collector |
| Proxmox VE 7/8 (single node or cluster) | `INT MON-VIRT Proxmox VE` (links official `Proxmox VE by HTTP`) | one host per cluster, e.g. `ACME-PRG-PVE` (no interface) | site proxy |
| Hyper-V (standalone or failover cluster) | `INT MON-VIRT Hyper-V` | each Hyper-V host (existing MON-SRV Windows host) | agent 2 active |

**Design decision (draft 4.2): VMs are items, not hosts.** One VM = items on the platform host (state, snapshots), so host counts and
billing stay predictable. A VM gets its own Zabbix host only when the customer buys MON-SRV for it (agent inside the VM).

**Why VMware is not a wrapper of the official template:** the official `VMware` template creates a Zabbix host for every hypervisor and
every VM in the shared groups `Applications` and `<datacenter name>` without customer tags. In a multi-tenant server that mixes
customers in one group, and alerts cannot be routed by `customer`. `INT MON-VIRT VMware vSphere` uses the same native collector keys
as the official templates, but keeps everything as items on the customer's vCenter host.

## Files

| File | Purpose |
|---|---|
| `template_int_mon_virt_vmware.yaml` | `INT MON-VIRT VMware vSphere` |
| `template_int_mon_virt_proxmox.yaml` | `INT MON-VIRT Proxmox VE` |
| `template_int_mon_virt_hyperv.yaml` | `INT MON-VIRT Hyper-V` |
| `hyperv/int_mon_virt_hyperv.ps1` | `C:\Program Files\Zabbix Agent 2\scripts\` |
| `hyperv/int_mon_virt_hyperv.conf` | `C:\Program Files\Zabbix Agent 2\zabbix_agent2.d\` |

## Triggers

| Trigger | Severity | VMware | Proxmox | Hyper-V |
|---|---|---|---|---|
| Hypervisor disconnected / offline | HIGH | connection state ≠ connected, 3 checks | official "Node offline" | MON-SRV agent unavailable |
| Cluster degraded | DISASTER (Hyper-V) / HIGH | cluster status red (HIGH), yellow WARNING | official "not quorum" (HIGH) | nodes down > 0 (DISASTER) |
| Host status red (hardware sensor / host alarm) | HIGH | `vmware.hv.status` red | – | MON-HW (iDRAC/iLO) |
| Host in maintenance too long | WARNING | > 4 h | – | – |
| Datastore / storage / CSV free space | AVERAGE / HIGH | < 15 % / < 5 % free | > 85 % / > 95 % used | < 15 % / < 5 % free |
| Datastore latency | AVERAGE | > 30 ms for 15 min | – | – |
| Snapshot / checkpoint older than 7 days | WARNING | yes | – (not in the cluster API) | yes |
| Critical VM not running | HIGH | `{$INT.VMWARE.VM.CRITICAL:"<vm>"}=1` | `{$INT.PVE.GUEST.CRIT.MATCHES}` regex | `{$INT.HV.VM.CRITICAL:"<vm>"}=1` |
| Memory ballooning (overcommit) | WARNING | ballooned > 0 for 1 h | – | – |
| Hyper-V Replica health | HIGH / AVERAGE | – | – | Critical / Warning |
| API not reachable | AVERAGE / HIGH | no data 30 min (AVERAGE) | official "API service not available" (HIGH) | – |

Not in v1.0: vCenter alarm mapping (cluster and host status already reflect red alarms), VMware Tools state,
MON-SRV-in-VM dependency on VM power state (host-level dependency, set it manually if needed).

## 1. What the customer provides

- **VMware:** read-only vCenter role (built-in *Read-only* is enough) for user e.g. `svc-zabbix@vsphere.local`; site proxy → vCenter HTTPS 443.
- **Proxmox:** API token with role `PVEAuditor` on `/` (Datacenter → Permissions → API Tokens; privilege separation on, role assigned to the token).
- **Hyper-V:** MON-SRV agent already on every host.
- List of VMs whose outage must alert (critical VMs) and the snapshot policy.

## 2. Proxy preparation (VMware only)

On the site proxy, `/etc/zabbix/zabbix_proxy.conf`: `StartVMwareCollectors=2`, `VMwareCacheSize=32M` (enough for an SMB vCenter),
then `systemctl restart zabbix-proxy`.

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

## 4. Configure hosts

Common: groups `Customers/<CUST>/<SITE>` + `Services/MON-VIRT`, tags `customer`, `site`, `managed`, `tier`, `contract`.

**VMware** `<CUST>-<SITE>-VCENTER`, monitored by the site proxy, no interface:

| Macro | Value |
|---|---|
| `{$VMWARE.URL}` | `https://vcenter.acme.local/sdk` |
| `{$VMWARE.USERNAME}` | `svc-zabbix@vsphere.local` |
| `{$VMWARE.PASSWORD}` | secret |
| `{$INT.VMWARE.VM.CRITICAL:"DC01"}` | `1` (one line per critical VM) |

**Proxmox** `<CUST>-<SITE>-PVE`, monitored by the site proxy, no interface:

| Macro | Value |
|---|---|
| `{$PVE.URL.HOST}` | `pve1.acme.local` (any cluster node) |
| `{$PVE.TOKEN.ID}` | `zabbix@pve!monitoring` |
| `{$PVE.TOKEN.SECRET}` | secret (token UUID) |
| `{$INT.PVE.GUEST.CRIT.MATCHES}` | `^(dc01\|erp01\|fs01)$` |

Then, if the customer keeps intentionally stopped VMs or templates: Data collection → Hosts → host → **Discovery** → disable the official
**QEMU discovery** and **LXC discovery** rules (otherwise every stopped guest raises an official AVERAGE "Not running").

**Hyper-V:** copy `int_mon_virt_hyperv.ps1` and `.conf` (see Files), `Restart-Service "Zabbix Agent 2"`, and link `INT MON-VIRT Hyper-V` on every
Hyper-V host next to `INT MON-SRV Windows`. Set `{$INT.HV.VM.CRITICAL:"<vm>"}=1` for critical VMs **on every node of a cluster**
(or on a host group via the onboarding tool), because the cluster owner node changes.

## 5. Verify

1. VMware: `vCenter: Version` has a value within 5 min; after discovery (1 h, or *Execute now* on the discovery rules) one item set per
   cluster, datastore, hypervisor and VM. `Host <name>: Connection state` = Connected.
2. Proxmox: official `API service status` = 1; `INT: Storage [...]: Space used, in %` matches the Proxmox GUI.
3. Hyper-V: `& "C:\Program Files\Zabbix Agent 2\zabbix_agent2.exe" -c "C:\Program Files\Zabbix Agent 2\zabbix_agent2.conf" -t int.hv.vms`
   prints the VM list. On a cluster, `-t int.hv.cluster` prints `"owner":1` on exactly one node.
4. Snapshot test: create a snapshot/checkpoint on a test VM and set `{$INT.VMWARE.SNAPSHOT.MAX.AGE:"<vm>"}=1m`
   (or `{$INT.HV.CHECKPOINT.MAX.AGE:"<vm>"}=1m`) → WARNING within one hour; delete snapshot and macro.
