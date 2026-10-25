# MON-SRV: server monitoring (Windows + Linux): installation

Version 1.0 · Zabbix 7.0.31 · built against official templates `release/7.0` (commit 362508f, 21 Oct 2026).
Draft reference: section 4.1, conventions 3.1.3–3.1.4.

## Files

| File | Where it goes |
|---|---|
| `template_int_mon_srv_windows.yaml` | Zabbix import. Template `INT MON-SRV Windows` (links `Windows by Zabbix agent active`) |
| `template_int_mon_srv_linux.yaml` | Zabbix import. Template `INT MON-SRV Linux` (links `Linux by Zabbix agent active`) |
| `template_int_mon_srv_smart.yaml` | Zabbix import. Template `INT MON-SRV SMART` (links `SMART by Zabbix agent 2 active`), physical servers only |
| `windows/int_mon_srv.ps1` | `C:\Program Files\Zabbix Agent 2\scripts\int_mon_srv.ps1` |
| `windows/int_mon_srv.conf` | `C:\Program Files\Zabbix Agent 2\zabbix_agent2.d\int_mon_srv.conf` |
| `linux/int-updates.sh`, `int-time.sh`, `int-cron-status.sh`, `int-kernel-errors.sh` | `/usr/local/lib/integrit/zabbix/` (root:root, 0755) |
| `linux/int-cron-wrap` | `/usr/local/bin/int-cron-wrap` (root:root, 0755) |
| `linux/int_mon_srv.conf` | `/etc/zabbix/zabbix_agent2.d/int_mon_srv.conf` |

## Decisions in this build (Asmir, 25 Oct 2026)

- **Availability:** no extra agent+ICMP trigger. `{$AGENT.TIMEOUT}` is lowered to 3m, so the official HIGH
  `Active checks are not available` fires after 3 min. Hosts with `tier=critical` get `{$INT.TIER.CRITICAL}=1`
  and an extra DISASTER `INT: Critical server is unreachable`. It fires together with the HIGH.
- **Filesystems:** official WARNING at 85 % and AVERAGE at 95 % (macro override). INT adds HIGH at 98 % and AVERAGE
  "will be full in < 14 days" (7-day linear forecast, only above 70 % used).
- **Linux "Number of installed packages has been changed":** left as is (tag `scope=notice`).
  **Integrit actions must have the condition `Tag scope does not equal notice`.** The same applies to the official
  "host has been restarted" and "system name changed" triggers. They stay visible in the frontend and in reports.
- **Windows services:** official discovery of all automatic services stays (AVERAGE). INT adds a per-host critical
  list (HIGH). Critical names must be excluded from the official discovery, or one stopped service raises two problems.

Other differences from draft 4.1:
- Linux cron uses `int-cron-wrap`. It writes a state file that the agent reads, so it needs no `zabbix_sender`
  and no PSK on cron hosts, and it keeps working through proxy outages.
- Linux critical units use the agent 2 systemd plugin as **active** items. The official systemd template is passive.
- The draft's "< 10 GB free on big volumes" rule is not built. Use per-filesystem macro context instead, e.g.
  `{$VFS.FS.PUSED.MAX.CRIT:"/data"}=98`. Note: the official Windows context is `"<label>(<drive>)"`, e.g.
  `{$VFS.FS.PUSED.MAX.CRIT:"Data(D:)"}`; INT macros use the plain FS name, e.g. `{$INT.VFS.FS.PUSED.MAX.HIGH:"D:"}`.

## 1. What the customer provides

- Local admin / root for the agent installation (or Integrit GPO/Intune package, Ansible).
- Server role(s), so you can choose the critical services/units (presets in step 4).
- Names of business-critical scheduled tasks / cron jobs and how often they run.
- Patch and maintenance window (create it as a Zabbix maintenance with data collection).
- Physical or virtual? (SMART template only on physical servers with disks visible to the OS.)
- Network: server → site proxy TCP 10051 outbound. Nothing inbound.

## 2. Install Zabbix agent 2 (7.0.x, active only, TLS PSK)

Generate one PSK per host: `openssl rand -hex 32`. Identity = host name, e.g. `ACME-PRG-SRV-DC01`.

### Windows

```bat
REM cmd.exe as administrator
msiexec /i zabbix_agent2-7.0.x-windows-amd64-openssl.msi /qn ^
  SERVER=127.0.0.1 SERVERACTIVE=<proxy IP or FQDN> HOSTNAME=ACME-PRG-SRV-DC01 ^
  TLSCONNECT=psk TLSACCEPT=psk TLSPSKIDENTITY=ACME-PRG-SRV-DC01 TLSPSKVALUE=<64 hex> ^
  HOSTMETADATA="INT;CUST=ACME;SVC=MON-SRV;OS=windows" SKIP=fw
```

Then:
1. Copy `int_mon_srv.ps1` to `C:\Program Files\Zabbix Agent 2\scripts\` and `int_mon_srv.conf` to `C:\Program Files\Zabbix Agent 2\zabbix_agent2.d\`.
2. In `zabbix_agent2.conf` make sure this line exists (the MSI only includes `plugins.d`):
   `Include=C:\Program Files\Zabbix Agent 2\zabbix_agent2.d\*.conf`
3. Physical server only: install smartmontools 7.1+ and set `Plugins.Smart.Path="C:\Program Files\smartmontools\bin\smartctl.exe"`.
4. `Restart-Service "Zabbix Agent 2"`.

### Linux (Debian 12 / Ubuntu 24.04 / RHEL 9 family)

Install `zabbix-agent2` from the official 7.0 repository (repo.zabbix.com). In `/etc/zabbix/zabbix_agent2.conf`:

```
Server=127.0.0.1
ServerActive=<proxy IP or FQDN>
Hostname=ACME-PRG-SRV-WEB01
HostMetadata=INT;CUST=ACME;SVC=MON-SRV;OS=linux
TLSConnect=psk
TLSAccept=psk
TLSPSKIdentity=ACME-PRG-SRV-WEB01
TLSPSKFile=/etc/zabbix/zabbix_agent2.psk
```

```bash
install -d -m 0755 /usr/local/lib/integrit/zabbix
install -m 0755 int-updates.sh int-time.sh int-cron-status.sh int-kernel-errors.sh /usr/local/lib/integrit/zabbix/
install -m 0755 int-cron-wrap /usr/local/bin/int-cron-wrap
install -m 0644 int_mon_srv.conf /etc/zabbix/zabbix_agent2.d/
install -d -m 1777 /var/lib/int-cron          # state files of int-cron-wrap
usermod -aG systemd-journal zabbix            # kernel error check reads the journal
chown zabbix:zabbix /etc/zabbix/zabbix_agent2.psk && chmod 0600 /etc/zabbix/zabbix_agent2.psk
systemctl restart zabbix-agent2
```

Physical server only: `apt install smartmontools` / `dnf install smartmontools`, add
`zabbix ALL=(ALL) NOPASSWD:/usr/sbin/smartctl` to `/etc/sudoers.d/zabbix` and set `Plugins.Smart.Path=/usr/sbin/smartctl`
(see the official SMART template description).

Wrap each monitored cron job (job name = letters, digits, `.`, `-`, `_`):

```
30 2 * * *  root  /usr/local/bin/int-cron-wrap db-dump /opt/scripts/db-dump.sh --full
```

Windows scheduled tasks need no change: put them in Task Scheduler folder `\Integrit\` or name them `INT-...`.

## 3. Import the templates (Zabbix 7.0 frontend)

Prerequisite: the official templates `Windows by Zabbix agent active`, `Linux by Zabbix agent active` and
`SMART by Zabbix agent 2 active` exist (default in 7.0). If the import fails with "item ... does not exist",
first re-import those three from `release/7.0` (git.zabbix.com or github.com/zabbix/zabbix, `templates/`).

Import each of the three INT files: **Data collection → Templates → Import** → choose file →

| Rule | Update existing | Create new | Delete missing |
|---|---|---|---|
| Template groups | TICK | TICK | UNTICKED |
| Templates | TICK | TICK | – |
| Template dashboards | TICK | TICK | UNTICKED |
| Template linkage | – | TICK | **UNTICKED** (never remove links) |
| Items | TICK | TICK | first import: UNTICKED · updates: TICK |
| Discovery rules | TICK | TICK | first import: UNTICKED · updates: TICK |
| Triggers | TICK | TICK | first import: UNTICKED · updates: TICK |
| Graphs | TICK | TICK | UNTICKED |
| Web scenarios | TICK | TICK | UNTICKED |
| Value maps | TICK | TICK | first import: UNTICKED · updates: TICK |

Click **Import**, then confirm the template group `Templates/Integrit/MON-SRV` holds all three templates.
"Delete missing" on updates only removes objects that were deleted from the INT files. It never touches the official templates.

## 4. Configure the host

1. **Data collection → Hosts → Create host** (or autoregistration action, see draft 3.1.5):
   - Host name `<CUST>-<SITE>-<name>`, visible name `ACME · DC01 (Praha)`.
   - Groups `Customers/<CUST>/<SITE>` and `Services/MON-SRV`.
   - Monitored by proxy `PXY-<CUST>-<SITE>`. No interface needed (active agent).
   - Encryption: Connections to host *PSK*, from host *PSK* only, same identity and key as the agent.
2. **Templates:** link only `INT MON-SRV Windows` **or** `INT MON-SRV Linux`. Do not link the official OS template
   separately. Physical server: also link `INT MON-SRV SMART`.
3. **Tags:** `customer`, `site`, `managed` (yes/no), `tier` (standard/critical), `contract`. `service=MON-SRV` comes from the template.
4. **Macros** (host level):

| Macro | When | Value |
|---|---|---|
| `{$INT.TIER.CRITICAL}` | tag `tier=critical` | `1` |
| `{$INT.SERVICE.CRIT.MATCHES}` | Windows, per role | presets below, combined with `\|` inside one `^(?:...)$` |
| `{$SERVICE.NAME.NOT_MATCHES}` | Windows, whenever the line above is set | official default + the same names (example below) |
| `{$INT.SYSTEMD.CRIT.MATCHES}` | Linux, per role | presets below |
| `{$INT.TASK.MAX.AGE:"<task name>"}` | weekly/monthly task | e.g. `8d`, `32d` (default 25h) |
| `{$INT.CRON.MAX.AGE:"<job>"}` | weekly/monthly cron job | e.g. `8d`, `32d` (default 25h) |
| `{$INT.EVENTLOG.SYSTEM.SOURCE}` / `{$INT.EVENTLOG.APP.SOURCE}` | extra event sources per role | extend the default regex |
| `{$INT.NTP.REF}` | Windows guest synced by Hyper-V (no offset otherwise) | DC or NTP host name, e.g. `dc01.acme.local` |

Windows critical service presets (service *names*, not display names):

| Role | Names |
|---|---|
| Domain controller | `NTDS\|DNS\|Netlogon\|Kdc\|DFSR\|W32Time` |
| File server | `LanmanServer\|DFSR\|Dfs` |
| Print server | `Spooler` |
| DHCP | `DHCPServer` |
| SQL Server | `MSSQLSERVER\|SQLSERVERAGENT\|MSSQL\$.+\|SQLAgent\$.+` |
| IIS | `W3SVC\|WAS` |
| RDS | `TermService\|Tssdis\|TSGateway\|TermServLicensing` |

Example DC + DHCP:
- `{$INT.SERVICE.CRIT.MATCHES}` = `^(?:NTDS|DNS|Netlogon|Kdc|DFSR|W32Time|DHCPServer)$`
- `{$SERVICE.NAME.NOT_MATCHES}` = `^(?:RemoteRegistry|MMCSS|gupdate|SysmonLog|clr_optimization_v.+|sppsvc|gpsvc|Pml Driver HPZ12|Net Driver HPZ12|MapsBroker|IntelAudioService|Intel\(R\) TPM Provisioning Service|dbupdate|DoSvc|CDPUserSvc_.+|WpnUserService_.+|OneSyncSvc_.+|WbioSrvc|BITS|tiledatamodelsvc|GISvc|ShellHWDetection|TrustedInstaller|TabletInputService|CDPSvc|wuauserv|edgeupdate|cbdhsvc_.+|NTDS|DNS|Netlogon|Kdc|DFSR|W32Time|DHCPServer)$`

Linux critical unit presets: SSH `ssh|sshd`, web `nginx|apache2|httpd|php.*-fpm`, database `postgresql.*|mariadb|mysql`,
containers `docker|containerd`. Example: `{$INT.SYSTEMD.CRIT.MATCHES}` = `^(?:sshd|nginx|php8\.2-fpm)\.service$`.

## 5. Verify

On the server (before or right after linking):

```powershell
# Windows (as admin)
& "C:\Program Files\Zabbix Agent 2\zabbix_agent2.exe" -c "C:\Program Files\Zabbix Agent 2\zabbix_agent2.conf" -t int.win.tasks
& "C:\Program Files\Zabbix Agent 2\zabbix_agent2.exe" -c "C:\Program Files\Zabbix Agent 2\zabbix_agent2.conf" -t int.win.updates
& "C:\Program Files\Zabbix Agent 2\zabbix_agent2.exe" -c "C:\Program Files\Zabbix Agent 2\zabbix_agent2.conf" -t "int.win.time[]"
```

```bash
# Linux: run as the zabbix user, because that is how the agent runs them
sudo -u zabbix /usr/local/lib/integrit/zabbix/int-updates.sh        # {"total":..,"security":..,"reboot_required":..,"last_patch_days":..}
sudo -u zabbix /usr/local/lib/integrit/zabbix/int-time.sh           # {"synced":1,"offset":...}
sudo -u zabbix /usr/local/lib/integrit/zabbix/int-kernel-errors.sh  # a number; an error means the journal group is missing
sudo -u zabbix /usr/local/lib/integrit/zabbix/int-cron-status.sh    # [] or job list
```

In Zabbix (**Monitoring → Hosts → host → Latest data**, filter tag `service`):
1. Host availability icon is green (ZBX active) within 2 min of restart.
2. `INT: FS [...]: Space used, in %` has values for every fixed disk / mount point.
3. `INT: Time: Offset to NTP source` has a value (Windows Hyper-V guests: only with `{$INT.NTP.REF}`).
4. `INT: Windows Update ...` / `INT: Updates ...` have values within 6 h (check interval).
5. Critical services/units and tasks/cron jobs appear within 1 h (discovery interval) or 5 min (tasks/cron).
6. **Trigger test:**
   - Windows: create task `\Integrit\INT-Test` running `cmd.exe /c exit 1`, run it once. Within about 10 min you get AVERAGE
     `INT: Task [\Integrit\INT-Test] failed`. Delete the task. The items disappear after the LLD lifetime.
   - Linux: `int-cron-wrap test-job false`. Within about 10 min you get AVERAGE `INT: Cron job [test-job] failed`.
     `int-cron-wrap test-job true` resolves it. Then `rm /var/lib/int-cron/test-job.json`.
   - Agent loss: stop the agent service. After 3 min you get HIGH `Active checks are not available` (and DISASTER if `{$INT.TIER.CRITICAL}=1`).
     Start it again.
7. Check that test problems carry tags `service:MON-SRV`, `customer`, `site`.

## Trigger overview (INT additions; official triggers stay as documented in the official README)

| Trigger | Severity | Default |
|---|---|---|
| Critical server is unreachable (tier critical) | DISASTER | `{$AGENT.TIMEOUT}`=3m, `{$INT.TIER.CRITICAL}`=1 |
| FS space is almost exhausted | HIGH | 98 % for 5 min |
| FS will be full in less than 14d | AVERAGE | 7-day forecast, > 70 % used; depends on the HIGH |
| Critical service / unit not running | HIGH | 3 checks (3 min) |
| Systemd has failed units (Linux) | WARNING | 3 checks |
| Task / cron job failed | AVERAGE | last result ≠ 0 |
| Task / cron job has not run | AVERAGE | > 25h (context per task/job) |
| Security updates pending | WARNING | Windows: oldest pending > 14 days; Linux: pending and no package change for 14 days |
| Reboot pending | WARNING | > 7 days after last update |
| Update status has no data | WARNING | 25h; depends on agent availability |
| Time drift | AVERAGE | > 60 s |
| Time is not synchronised | WARNING | 1h; depends on time drift |
| Repeated disk/storage errors (System log / kernel) | AVERAGE | ≥ 3 in 15 min |
| Repeated VSS errors (Windows) | AVERAGE | ≥ 3 in 15 min |
| SMART (official, via INT MON-SRV SMART) | HIGH / AVERAGE | official defaults |

Notes:
- Dependencies on the site gateway and proxy come from MON-NET (host-level dependencies on the gateway trigger, draft 3.2.4).
  Without MON-NET a site outage raises one HIGH per server.
- Patch windows: create a maintenance *with data collection* per customer, so that reboot pending and restarts do not alert.
