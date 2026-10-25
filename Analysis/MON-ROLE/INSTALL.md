# MON-ROLE: server role packs: installation

Version 1.0 · Zabbix 7.0.31. Draft reference: section 5.6.3.

Add-on to MON-SRV, sold per role and server (draft recommendation: MON-SRV Standard / Plus = up to 3 role packs). Each pack is a
template linked **next to** `INT MON-SRV Windows` / `INT MON-SRV Linux` on the same host (agent 2, active).

| Template | Role | Data |
|---|---|---|
| `INT MON-ROLE File server` | Windows file server | shares online, shadow copies (age, sudden drop), FSRM quotas, DFS-R backlog, LanmanServer / DFSR |
| `INT MON-ROLE DHCP server` | Windows DHCP | scope use, failover state, DHCPServer |
| `INT MON-ROLE DNS server` | Windows DNS | local internal / internet resolution, forwarders, AD zone errors, DNS service |
| `INT MON-ROLE Print server` | Windows print | queues in error, stuck jobs, Spooler |
| `INT MON-ROLE RDS` | Remote Desktop Services | licensing grace period, CALs, sessions vs capacity, RDS services |
| `INT MON-ROLE IIS` | IIS | application pools, request queues, W3SVC / WAS |
| `INT MON-ROLE Nginx` / `Apache` / `PHP-FPM` | Linux web | official agent-active templates |

Not in v1.0: Linux BIND, DHCP conflict events, IIS 5xx rate (needs log parsing), RDS Gateway connections.
Exchange → MON-MAIL, Hyper-V → MON-VIRT, SQL → MON-DB, domain controllers → MON-AD.

## Files

| File | Where |
|---|---|
| `template_int_mon_role.yaml` | Zabbix import |
| `windows/int_mon_role.ps1` | `C:\Program Files\Zabbix Agent 2\scripts\int_mon_role.ps1` |
| `windows/int_mon_role.conf` | `C:\Program Files\Zabbix Agent 2\zabbix_agent2.d\int_mon_role.conf` |

## Triggers

| Trigger | Severity | Default |
|---|---|---|
| Role service not running (3 checks) | HIGH | services from `{$INT.ROLE.<ROLE>.SERVICES}` |
| Share offline (folder missing) · share no longer exists | HIGH · AVERAGE | 2 checks · 1 h |
| Shadow copies dropped by > 50 % at once (ransomware indicator) | HIGH | vs the 1-day maximum |
| Newest shadow copy too old | AVERAGE | > 26 h |
| FSRM quota | WARNING / AVERAGE | > 85 % / > 95 % |
| DFS-R backlog | AVERAGE | > 1000 files for 1 h (checked every 30 min) |
| DHCP scope use | AVERAGE / HIGH | > 85 % / > 95 % for 10 min |
| DHCP failover not Normal | HIGH | 2 checks |
| DNS: internal / internet names not resolving | HIGH | 2 checks |
| DNS forwarders not answering · AD zone errors | WARNING · AVERAGE | – |
| Print queues in error · jobs stuck | WARNING | 15 min |
| RDS grace period ending · CALs nearly exhausted | HIGH | ≤ 30 days · < 5 left |
| RDS sessions over capacity | WARNING | > 30 for 30 min |
| IIS application pool not running · request queue | HIGH · WARNING | 3 checks · > 100 for 5 min |

All packs depend on the host being up: MON-SRV agent / host triggers cover that (no extra dependency needed, the agent items stop).

## 1. What the customer provides

- Which roles run on which servers.
- Scopes / shares / quotas in scope (defaults: all), RDS capacity (sessions per host) and CAL type / count.
- Backup windows if the backup product deletes shadow copies (then the "dropped" trigger needs a maintenance window).

## 2. Agent files (every role server)

Copy `int_mon_role.ps1` and `int_mon_role.conf`, `Restart-Service "Zabbix Agent 2"`. PowerShell modules used are part of the role
(DhcpServer, SmbShare, FileServerResourceManager, DFSR, PrintManagement, DnsServer).

## 3. MON-SRV service lists

Role services are watched by the role pack (HIGH). So that the official MON-SRV discovery does not alert a second time (AVERAGE),
append the role's services inside `{$SERVICE.NAME.NOT_MATCHES}` on the host (MON-SRV INSTALL step 4) and do **not** put them in
`{$INT.SERVICE.CRIT.MATCHES}`:

| Pack | Services |
|---|---|
| File server | `LanmanServer`, `DFSR` (DFS-R members) |
| DHCP | `DHCPServer` |
| DNS | `DNS` (on a DC: leave `{$INT.ROLE.DNS.SERVICES}` empty, MON-AD already watches DNS) |
| Print | `Spooler` |
| RDS | `TermService`, `SessionEnv`, `Tssdis`, `TSGateway`, `TermServLicensing` (those present) |
| IIS | `W3SVC`, `WAS` |

Each pack writes the service key in its own form (`service.info[X]`, `[X,]`, `["X",]`, `[X,""]`, `[X,"state"]`,
`["X","state"]`). All of them read the service state; the different spelling only keeps the keys unique, so several packs
(e.g. DHCP + DNS + Print on one DC) can be linked on the same host. Do not "tidy" them to one form.

## 4. Import

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

## 5. Hosts

Link the pack(s) on the existing MON-SRV host, add group `Services/MON-ROLE`. Typical host macros:

| Macro | Example |
|---|---|
| `{$INT.ROLE.FILE.SERVICES}` | `LanmanServer;DFSR` |
| `{$INT.ROLE.SHARE.NOT_MATCHES}` | `^(print\$|prnproxy|NETLOGON|SYSVOL|Scans)$` |
| `{$INT.ROLE.DFSR.MAX}` | `5000` for large initial syncs |
| `{$INT.ROLE.DHCP.SCOPE.NOT_MATCHES}` | `^10\.99\.` (lab scope) |
| `{$INT.ROLE.DNS.INTERNAL}` | `dc01.acme.local` |
| `{$INT.ROLE.RDS.SERVICES}` | Session host `TermService;SessionEnv`; broker `Tssdis`; gateway `TSGateway`; licensing `TermServLicensing` |
| `{$INT.ROLE.RDS.SESSIONS.MAX}` | `25` |

Linux web packs: the status pages must be reachable from the agent on localhost:
- Nginx: `location = /basic_status { stub_status; allow 127.0.0.1; deny all; }` in a server on port 80 (or set `{$NGINX.STUB_STATUS.PORT}`).
- Apache: `mod_status` with `<Location "/server-status"> SetHandler server-status; Require local </Location>`.
- PHP-FPM: `pm.status_path = /status` and `ping.path = /ping` in the pool, proxied by the web server on localhost.

## 6. Verify

1. On the server: `zabbix_agent2.exe -c "C:\Program Files\Zabbix Agent 2\zabbix_agent2.conf" -t int.role.dhcp` (and `int.role.shares`,
   `int.role.vss`, `int.role.rds`, `int.role.dns[dc01.acme.local,www.microsoft.com]`, `int.role.print[15]`) → JSON.
2. Latest data: one item per scope / share / quota / volume with shadow copies; `Service <name>: state` = Running.
3. File server test: `vssadmin list shadows` count matches `Volume <X>: shadow copies`.

Not tested in the build environment: the PowerShell script (no Windows here). DFS-R backlog can take minutes on large groups: the
item timeout is 300 s; raise `{$INT.ROLE.DFSR.INTERVAL}` if needed.
