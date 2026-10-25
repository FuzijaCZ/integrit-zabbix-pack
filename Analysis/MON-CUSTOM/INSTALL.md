# MON-CUSTOM: custom application and integration checks: installation

Version 1.0 · Zabbix 7.0.31. Draft reference: section 4.16.

MON-CUSTOM is a **framework**: six small pattern templates plus a check card (`CHECK-CARD.md`, Czech, customer documentation).
Each pattern takes its checks from one host macro (`entry;entry`, fields separated by `|`), so one host can have any number of checks per pattern
without editing templates. No check is built without a filled and approved check card.

## Files

| File | Purpose |
|---|---|
| `template_int_mon_custom.yaml` | the six pattern templates below |
| `scripts/int-job-run` | Linux job wrapper → `/usr/local/bin/int-job-run` |
| `scripts/int-job-report.ps1` | Windows job reporting → `C:\Program Files\Zabbix Agent 2\scripts\` |
| `CHECK-CARD.md` | check card (fill before building) |

## Patterns

| Template | Macro (entry format) | Collected by | Triggers (default severity) |
|---|---|---|---|
| `INT MON-CUSTOM Job` | `{$INT.CUSTOM.JOBS}` = `job\|max-age` e.g. `erp-export\|25h` | job wrapper → zabbix_sender (trapper) | failed HIGH · no report within max age HIGH · duration > 2× 30-day median WARNING |
| `INT MON-CUSTOM File` | `{$INT.CUSTOM.FILES}` = `label\|path\|max-age\|min-bytes` | agent 2 active | not updated / missing HIGH · smaller than min AVERAGE |
| `INT MON-CUSTOM Log` | `{$INT.CUSTOM.LOGS}` = `label\|path\|regex\|count` | agent 2 active (`log[]`) | ≥ count matches in 15 min AVERAGE |
| `INT MON-CUSTOM Process` | `{$INT.CUSTOM.PROCS}` = `label\|process\|min` | agent 2 active (`proc.num`) | fewer than min for 3 min HIGH |
| `INT MON-CUSTOM HTTP` | `{$INT.CUSTOM.URLS}` = `label\|url\|body-regex` | HTTP agent on the proxy | not 200 + match twice HIGH |
| `INT MON-CUSTOM TCP` | `{$INT.CUSTOM.PORTS}` = `label\|host\|port` | simple check on the proxy | port closed 3× HIGH |

Severity defaults follow draft 4.16. If a check card requires a different severity, use a separate host with a copied **INT** template.
Never copy an official one.

Not in v1.0: database query pattern (use the MON-DB plugins per card), composite checks (calculated items per card, built by hand on the host).

Examples:

```
{$INT.CUSTOM.JOBS}  = erp-export|25h;eshop-import|2h
{$INT.CUSTOM.FILES} = pohoda-xml|D:\Export\pohoda.xml|25h|1024;edi-in|/srv/edi/in/orders.csv|2h|1
{$INT.CUSTOM.LOGS}  = erp|C:\ERP\logs\server.log|ERROR\|FATAL|3
{$INT.CUSTOM.PROCS} = erp-server|ErpServer.exe|1
{$INT.CUSTOM.URLS}  = shop-api|https://api.acme.cz/health|"status":"ok"
{$INT.CUSTOM.PORTS} = pohoda-sql|srv-db01.acme.local|1433
```

## 1. What the customer provides

The filled check card: purpose, owner, signal, schedule, expected result, thresholds, who gets alerts, runbook. For jobs: permission to wrap the
scheduled task / cron line with the Integrit wrapper.

## 2. Job wrappers

**Linux:** `install -m 0755 int-job-run /usr/local/bin/`; install the `zabbix-sender` package (7.0, repo.zabbix.com). Change the cron line:

```
0 2 * * *  root  /usr/local/bin/int-job-run erp-export /opt/erp/export.sh
```

The wrapper uses `/etc/zabbix/zabbix_agent2.conf` (ServerActive, Hostname, TLS PSK), so run the job as root or as a user who can read the PSK file.

**Windows:** copy `int-job-report.ps1`; install the agent MSI with the **Zabbix sender** feature (`zabbix_sender.exe` next to the agent). In Task Scheduler, change
the action to:
`powershell.exe -NoProfile -ExecutionPolicy Bypass -File "C:\Program Files\Zabbix Agent 2\scripts\int-job-report.ps1" -Job erp-export -Run "C:\ERP\export.cmd"`.
Or call it at the end of your own script with `-ExitCode`, `-Duration`, `-Records`, `-Message`.

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

Agent-based patterns (Job, File, Log, Process): on the existing MON-SRV host of that server. Network patterns (HTTP, TCP): on the server's host
or on a separate host `<CUST>-APP-<name>`, monitored by the site proxy (internal URL / port) or the external proxy (public URL).
Add the `Services/MON-CUSTOM` group and keep the usual tags. Set the macro(s) from the check card.

## 5. Verify

1. Discovery runs hourly: Data collection → host → Discovery → `Checks from {$INT.CUSTOM...}` → **Execute now**; one item set per entry appears.
   A wrong entry (wrong number of fields) shows the error on the discovery rule.
2. Job: run the job once by hand → `Job <name>: Exit code` = 0 and `Duration` within a minute. Run with a failing command
   (`int-job-run test false` with `test|1h` in the macro) → HIGH "failed".
3. File / Log / Process / HTTP / TCP: Latest data shows values within 5 min; break one on purpose (rename the file, stop the process) to see the trigger.
4. Store the filled check card with the customer documentation.
