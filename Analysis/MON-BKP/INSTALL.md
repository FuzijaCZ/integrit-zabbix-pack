# MON-BKP: backup monitoring: installation

Version 1.0 · Zabbix 7.0.31 · official templates `release/7.0` (commit 362508f). Draft reference: section 4.4.

One data model for every product: per job **last result**, **last successful run**, message, and for Veeam REST also duration.
Every job gets a **freshness** trigger ("no successful backup for X"), because the dangerous failure is silence.

## Which connector for which product

| Product | Template | Host it goes on | Collected by |
|---|---|---|---|
| Veeam B&R 12+ with REST API (VUL Foundation/Advanced/Premium, Enterprise Plus socket) | `INT MON-BKP Veeam Backup and Replication` | separate host `<CUST>-<SITE>-VBR01` (or the VBR server's MON-SRV host) | site proxy → VBR TCP 9419 |
| Veeam B&R Community / Standard (no REST API), Veeam Agent managed by VBR | `INT MON-BKP E-mail reports` (Veeam rule) | host for the VBR server | e-mail parser |
| Veeam Agent for Windows, standalone, one job | `INT MON-BKP Veeam Agent for Windows` | the protected server (MON-SRV host) | agent 2 active, event log |
| Windows Server Backup | `INT MON-BKP Windows Server Backup` | the protected server (MON-SRV host) | agent 2 active, event log |
| Synology Hyper Backup / Active Backup for Business, anything else that only mails | `INT MON-BKP E-mail reports` | host for the device, e.g. `ACME-PRG-NAS01` | e-mail parser |
| Acronis Cyber Protect Cloud | official `Acronis Cyber Protect Cloud by HTTP` (not wrapped in v1.0) | – | external proxy |
| E-mail parser health (once, Integrit) | `INT MON-BKP E-mail parser` | `INT-PLATFORM-BKP-PARSER` in `Integrit/Platform` | e-mail parser |

## Files

| File | Purpose |
|---|---|
| `template_int_mon_bkp_veeam_br.yaml` | `INT MON-BKP Veeam Backup and Replication` (links official `Veeam Backup and Replication by HTTP`) |
| `template_int_mon_bkp_eventlog.yaml` | `INT MON-BKP Veeam Agent for Windows`, `INT MON-BKP Windows Server Backup` |
| `template_int_mon_bkp_email.yaml` | `INT MON-BKP E-mail reports`, `INT MON-BKP E-mail parser` |
| `parser/int-bkp-mail-parser.py` | parser (Python 3.9+, standard library only) |
| `parser/bkp-mail-rules.json` | subject rules: Veeam, Synology EN/CZ |
| `parser/bkp-mail-parser.json` | parser config (fill `client_id`) |
| `parser/int-bkp-mail-parser.service`, `.timer` | systemd units, run every 5 min |

## Triggers

| Trigger | Severity | Default (macro, context = job name) |
|---|---|---|
| Job failed | HIGH | last result = Failed |
| Job ended with warning | WARNING | last result = Warning |
| Job ends with warning for a period / N times | AVERAGE | Veeam REST: all results in `{$INT.BKP.WARN.PERIOD}`=3d · e-mail: ≥ `{$INT.BKP.WARN.COUNT}`=3 warnings and nothing else in 3d |
| No successful backup | HIGH | `{$INT.BKP.MAX.AGE}`=26h |
| No successful backup (2 windows) | DISASTER | `{$INT.BKP.MAX.AGE.DISASTER}`=52h |
| Run took longer than usual (Veeam REST) | WARNING | > `{$INT.BKP.DURATION.FACTOR}`=3 × 30-day median, after 7 runs |
| Repository free space (Veeam REST) | AVERAGE / HIGH | < 15 % / < 5 % |
| Veeam API errors (official) | AVERAGE | no data from the connector; INT freshness triggers depend on it |
| E-mail parser not running / error | AVERAGE | no heartbeat for 30 min |
| E-mail parser could not parse a report | WARNING | unknown format or no `+HOST` in recipient |

Weekly or monthly jobs: set both freshness macros with context on the host, e.g.
`{$INT.BKP.MAX.AGE:"Offsite weekly"}=8d` and `{$INT.BKP.MAX.AGE.DISASTER:"Offsite weekly"}=15d`.
Intentionally paused jobs: add them to `{$INT.BKP.JOB.NAME.NOT_MATCHES}` (disabled Veeam jobs are skipped automatically).

Not in v1.0 (draft optional items): backup product licence expiry, immutability status. Duration anomaly exists only for
Veeam REST, because e-mail and event connectors carry no reliable duration.

## 1. What the customer provides

- The backup plan: list of jobs, schedule (daily / weekly), retention, owner of each job.
- Veeam REST: a Veeam user with role **Veeam Backup Viewer** (read-only) and network access site proxy → VBR TCP 9419.
- E-mail products: the device's notification settings changed so reports go to `backup-reports+<HOST>@integrit.cz`
  (e.g. `backup-reports+ACME-PRG-NAS01@integrit.cz`), notifications enabled for success, warning **and** failure.
- Event-log products: MON-SRV agent already installed on that server.

## 2. One-time Integrit setup: e-mail parser (skip if only Veeam REST / event logs are used)

1. **Mailbox:** shared mailbox `backup-reports@integrit.cz` (no licence needed). Plus addressing is on by default in
   Exchange Online; check with `Get-OrganizationConfig | fl AllowPlusAddressInRecipients` (must be True).
2. **Entra app** "Integrit Zabbix Backup Reports": App registrations → New → single tenant. Certificates & secrets →
   new client secret (24 months; put the expiry in MON-CERT later). Do **not** add Mail.Read in API permissions
   (that would allow every mailbox).
3. **Restrict to one mailbox** (Exchange Online PowerShell, RBAC for Applications):

   ```powershell
   Connect-ExchangeOnline
   New-ServicePrincipal -AppId <client id> -ObjectId <object id of the Enterprise application> -DisplayName "Integrit Zabbix Backup Reports"
   New-ManagementScope -Name "INT backup reports mailbox" -RecipientRestrictionFilter "PrimarySmtpAddress -eq 'backup-reports@integrit.cz'"
   New-ManagementRoleAssignment -App <client id> -Role "Application Mail.Read" -CustomResourceScope "INT backup reports mailbox"
   Test-ServicePrincipalAuthorization -Identity <client id> -Resource backup-reports@integrit.cz   # InScope = True
   ```
4. **Install on the external proxy** (Debian/Ubuntu, `zabbix-sender` 7.0 package from repo.zabbix.com):

   ```bash
   useradd --system --no-create-home --shell /usr/sbin/nologin int-bkp-parser
   install -d -m 0755 /usr/local/lib/integrit/bkp-mail-parser /etc/integrit
   install -m 0755 int-bkp-mail-parser.py /usr/local/lib/integrit/bkp-mail-parser/
   install -m 0644 bkp-mail-rules.json /usr/local/lib/integrit/bkp-mail-parser/
   install -m 0640 -g int-bkp-parser bkp-mail-parser.json /etc/integrit/      # set client_id
   install -m 0640 -g int-bkp-parser /dev/null /etc/integrit/bkp-mail-parser.secret   # paste the client secret value
   install -m 0644 int-bkp-mail-parser.service int-bkp-mail-parser.timer /etc/systemd/system/
   systemctl daemon-reload && systemctl enable --now int-bkp-mail-parser.timer
   ```
   `zabbix_server` = `127.0.0.1`, because the external proxy itself receives the trapper values (the hosts using
   `INT MON-BKP E-mail reports` must be **monitored by this external proxy**, not by the site proxy). If the proxy requires PSK
   for trapper data, fill `tls_psk_identity` / `tls_psk_file`.
5. Create host `INT-PLATFORM-BKP-PARSER` (group `Integrit/Platform`, monitored by the external proxy, no interface),
   link `INT MON-BKP E-mail parser`.
6. Test a new format before relying on it: `int-bkp-mail-parser.py --test-subject "<subject of a real report>"`.
   If it prints `NO MATCH`, add a rule to `bkp-mail-rules.json` (regex with groups `job` and `result`).

## 3. Import the templates

**Data collection → Templates → Import**, the three YAML files one by one:

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

`Veeam Backup and Replication by HTTP` must already exist (default in 7.0). If not, import it from `release/7.0` first.

## 4. Configure hosts

Common: host name `<CUST>-<SITE>-<name>`, groups `Customers/<CUST>/<SITE>` + `Services/MON-BKP`, tags `customer`, `site`,
`managed`, `tier`, `contract`.

**Veeam REST:** monitored by the site proxy, no interface. Link `INT MON-BKP Veeam Backup and Replication`. Host macros:

| Macro | Value |
|---|---|
| `{$VEEAM.API.URL}` | `https://vbr01.acme.local:9419` |
| `{$VEEAM.USER}` | e.g. `ACME\svc-zabbix-veeam` |
| `{$VEEAM.PASSWORD}` | type **Secret text** |
| `{$HTTP.TLS.VERIFY:"Veeam Backup and Replication"}` | `none` while VBR uses its self-signed certificate; `full` with a trusted certificate |

**Event logs:** on the existing MON-SRV Windows host, additionally link `INT MON-BKP Veeam Agent for Windows` and/or
`INT MON-BKP Windows Server Backup`. Set `{$INT.BKP.MAX.AGE}` / `{$INT.BKP.MAX.AGE.DISASTER}` if the job is not daily.

**E-mail reports:** host named exactly like the `+HOST` part of the recipient, **monitored by the external proxy**, no interface.
Link `INT MON-BKP E-mail reports`. Jobs appear after the first report (first report: discovery; values from the next parser run, ≤ 5 min).

## 5. Verify

1. **Veeam REST:** Latest data → `Get metrics` has JSON without `"error"`; item `INT: Job [...]: Last result` exists for every
   enabled job within 10 min; `Last successful run` shows a date after the first successful session of the last 7 days.
2. **Veeam Agent / WSB:** run a backup manually. Latest data → `INT: Veeam Agent: Job finished events` / `INT: Windows Server Backup: Result events`
   gets the event within 1 min.
3. **E-mail:** send a test mail to `backup-reports+<HOST>@integrit.cz` with subject `[Failed] INT test job (1 VMs) 1 failed`.
   Within 10 min the host shows job `INT test job` and the HIGH `INT: Job [INT test job] failed`. Then send `[Success] INT test job (1 VMs)`:
   the problem resolves. Remove the test job: add it to `{$INT.BKP.JOB.NAME.NOT_MATCHES}`.
4. Parser: `journalctl -u int-bkp-mail-parser --since -1h` shows no `ERROR`; host `INT-PLATFORM-BKP-PARSER` → `INT: Parser: Last run` is fresh.
5. Freshness: on a test job set `{$INT.BKP.MAX.AGE:"<job>"}=1m` → HIGH appears within 1–2 min; remove the macro.
