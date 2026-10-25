# Pilot on the first customer

Two parts: what was already run against a real Zabbix 7.0.31 (part 1, done), and what only works at a customer (part 2, to do).
Fill the **Result** column in part 2 while you go; anything that is not "OK" goes back to the repo as a fix.

## 1. Already tested on a real Zabbix 7.0.31 (2026-10-25)

Lab: official Docker images `zabbix-server-pgsql` + `zabbix-web-nginx-pgsql` `alpine-7.0.31`, PostgreSQL 16, Admin API.

| Check | How | Result |
|---|---|---|
| Import of all 50 YAML files (templates + media type) | `configuration.import`, boxes as in every INSTALL | 49 OK first time. **Fixed:** MON-SECEVT used `{$INT.SECEVT.WINDOW}m` as interval (a macro plus a suffix is not a valid interval); now `{$INT.SECEVT.INTERVAL}` = `5m` |
| Link every one of the 90 `INT` templates to its own host | `host.create` with agent, SNMP, IPMI, JMX interfaces | 90 / 90 OK |
| Link real stacks on one host | Windows DC/file/RDS server (27 templates), Linux server (18), FortiGate gateway, M365 tenant host | **Fixed:** MON-ROLE packs could not sit together (DHCP + DNS + Print on one DC failed: same `service.info[{#SERVICE}]` prototype in every pack). Each pack now has its own spelling of the key, also different from MON-AD, MON-SRV and SRV-SHUTDOWN. **Documented:** `INT MON-NET MikroTik` + `INT MON-LAN MikroTik` cannot share one host (both link `Mikrotik by SNMP`); a MikroTik gateway gets only the MON-NET one |
| Every Script item, Script LLD and the webhook (45) | Run in the server's own JavaScript engine (Duktape), via the same `item.test` call the UI "Test" button uses | All compile and run. **Fixed:** 7 error messages printed an empty macro name ("Macro  is not set."), because the server expands `{$...}` inside the script text. They now show the macro name |
| Every JavaScript preprocessing step (41) | Same engine, dummy input | All compile. Real output needs real data (part 2) |
| Graph / Entra token flow (M365, Entra ID, Intune, Intune Apple, Azure, MON-WEB-FUNC mail) | Live calls to `login.microsoftonline.com` with a non-existent tenant | Request accepted by Microsoft and the error (`AADSTS90002 tenant not found`) is passed through to the `... errors` item as designed |
| ESET Connect token flow | Live call to `eu.business-account.iam.eset.systems` with a dummy user | `invalid_username_or_password` passed through as designed |
| CISA KEV feed (MON-EXPOSURE) | Live download | OK, catalog 2026.10.23 parsed |
| 8 PowerShell scripts | PowerShell 7 parser + PSScriptAnalyzer, syntax target Windows PowerShell 5.1 | All parse; no errors. Only warnings: 3 intentionally empty `catch` blocks |
| Agent keys vs. UserParameter files | Every `int.*` agent key in the templates has a `UserParameter` (34 / 34) | OK |
| Python external scripts (5) and shell scripts (7) | Compile / `bash -n`, run with no arguments | OK |

Not possible in the lab: anything that needs Windows, a customer tenant, an Azure subscription, a Hikvision recorder or SNMP devices.
That is part 2.

## 2. To do at the first customer

Order as in `Analysis/README.md`. Per row: follow the **Verify** section of that INSTALL, write the result, and for a failure note the
exact item error (Latest data → item → the red **i** icon) or the script output.

### 2a. Windows PowerShell scripts (run on the server, as admin, before linking)

```powershell
$a = "C:\Program Files\Zabbix Agent 2\zabbix_agent2.exe"; $c = "C:\Program Files\Zabbix Agent 2\zabbix_agent2.conf"
& $a -c $c -t <key>      # one line per key from the INSTALL; a JSON or a number is OK, "ZBX_NOTSUPPORTED" or a PowerShell error is a fail
```

| Service | Script | INSTALL section | Server used | Result |
|---|---|---|---|---|
| MON-SRV | `windows/int_mon_srv.ps1` | MON-SRV §5 | | |
| MON-SECEVT | `windows/int_mon_secevt.ps1` | MON-SECEVT §6 | | |
| MON-AD | `windows/int_mon_ad.ps1` (on the PDC emulator and one other DC) | MON-AD §5 | | |
| MON-ROLE | `windows/int_mon_role.ps1` (file, DHCP, DNS, print, RDS, IIS as present) | MON-ROLE §6 | | |
| MON-CERT | `windows/int_mon_cert.ps1` (one server + the CA) | MON-CERT §6 | | |
| MON-VIRT | `hyperv/int_mon_virt_hyperv.ps1` (cluster owner node and one other) | MON-VIRT §5 | | |
| MON-MAIL | `windows/int_mon_mail_exchange.ps1` (only if Exchange on-prem) | MON-MAIL §7 | | |
| MON-CUSTOM | `scripts/int-job-report.ps1` (one scheduled job) | MON-CUSTOM §5 | | |

Watch for: execution policy (the `.conf` files call `-ExecutionPolicy Bypass`), agent `Timeout` (some keys run 10 to 30 s),
Czech-language Windows (event text and service display names differ; the scripts must use IDs and service short names).

### 2b. Microsoft Graph / Entra (one customer tenant)

| Service | Template | INSTALL section | Result |
|---|---|---|---|
| MON-M365 | `INT MON-M365 Tenant` | MON-M365 §4 | |
| MON-IDSEC | `INT MON-IDSEC Entra ID` | MON-IDSEC §5 | |
| MON-MDM | `INT MON-MDM Intune` | MON-MDM §5 | |
| MON-CERT | `INT MON-CERT Intune Apple` (only with Apple devices in Intune) | MON-CERT §6 | |
| MON-MAIL | `INT MON-MAIL Plus` (end-to-end mail test) | MON-MAIL §7 | |
| MON-WEB-FUNC | mailbox check of `Scenario` | MON-WEB-FUNC §5 | |

First check after **Execute now**: the `... errors` item is empty. If it shows `403` / `Authorization_RequestDenied`, an application
permission or admin consent is missing: write down which call failed, that is a fix to the permission list in the INSTALL.

### 2c. Azure (one subscription, via Lighthouse)

| Check | INSTALL section | Result |
|---|---|---|
| Lighthouse offer accepted, three read-only roles visible | MON-CLOUD §5 step 4 | |
| `INT MON-CLOUD Azure subscription`: `Azure: API errors` empty, VM count right | MON-CLOUD §5 step 1 | |
| Cost item next day vs. Cost analysis | MON-CLOUD §5 step 2 | |
| One VM, one SQL DB, one backup vault host | MON-CLOUD §5 step 3 | |

### 2d. Hikvision (one NVR and one camera)

| Check | INSTALL section | Result |
|---|---|---|
| `Recorder: ISAPI raw` → Execute now, `API error` empty, model / firmware filled | MON-CCTV §5 step 1 | |
| Channels discovered (older DVR: may be none, then note model + firmware) | MON-CCTV §5 step 2 | |
| Retention vs. playback calendar | MON-CCTV §5 step 3 | |
| Camera unplugged → "offline" fires, "not recording" suppressed | MON-CCTV §5 step 4 | |

Note the NVR model and firmware either way: ISAPI differs between firmware lines.

### 2e. SNMP OIDs never seen on real hardware

QNAP (MON-NAS), APC rack PDU (MON-ENV), the sensor unit you have (MON-ENV). For each: does discovery find the volumes / outlets /
sensors, and do the values match the device web UI?

## 3. Sending results back

Paste the filled tables (or just the failing rows with the error text) into the project chat. Each failure becomes one fix commit to
the service folder, re-tested in the lab where possible.
