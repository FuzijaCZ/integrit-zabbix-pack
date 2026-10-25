# MON-MAIL: mail flow, mail domain security and mail servers: installation

Version 1.0 · Zabbix 7.0.31. Draft reference: section 5.6.10.

| Template | Linked on | Collected by |
|---|---|---|
| `INT MON-MAIL Basic` | one host per mail domain (e.g. `MAIL acme.cz`) | external proxy, ExternalScript `int-mail-check.py` |
| `INT MON-MAIL Plus` | the same domain host, if the customer buys Plus (Microsoft 365 only) | external proxy, Script item (Microsoft Graph) |
| `INT MON-MAIL Exchange` | on-prem Exchange 2016 / 2019 / SE server, next to `INT MON-SRV Windows` | agent 2 on the server (active) |
| `INT MON-MAIL Postfix` | Postfix server, next to `INT MON-SRV Linux` | agent on the server (active) |

## Files

| File | Where |
|---|---|
| `template_int_mon_mail_domain.yaml` | Zabbix import (Basic + Plus) |
| `template_int_mon_mail_servers.yaml` | Zabbix import (Exchange + Postfix) |
| `externalscripts/int-mail-check.py` | external proxy: `/usr/lib/zabbix/externalscripts/int-mail-check.py` (0755, root) |
| `windows/int_mon_mail_exchange.ps1` | `C:\Program Files\Zabbix Agent 2\scripts\int_mon_mail_exchange.ps1` |
| `windows/int_mon_mail_exchange.conf` | `C:\Program Files\Zabbix Agent 2\zabbix_agent2.d\int_mon_mail_exchange.conf` |
| `linux/int-postfix-queue.sh` | `/usr/local/lib/integrit/zabbix/int-postfix-queue.sh` (0755, root) |
| `linux/int_mon_mail_postfix.conf` | `/etc/zabbix/zabbix_agent2.d/int_mon_mail_postfix.conf` (agent 1: `/etc/zabbix/zabbix_agentd.d/`) |

## Triggers

| Trigger | Severity | Default |
|---|---|---|
| Domain has no MX record | HIGH | – |
| No MX answers on port 25 | HIGH | 2 checks in a row (5 min interval) |
| STARTTLS certificate expired / invalid (chain, name) | HIGH | 2 checks in a row for invalid |
| STARTTLS certificate expires soon | AVERAGE | < 14 days |
| MX does not offer STARTTLS | AVERAGE | 2 checks in a row |
| SPF missing / invalid / > 10 lookups / no `-all`/`~all` | AVERAGE | – |
| No DMARC record · DMARC `p=none` | WARNING · INFO | – |
| DKIM selector missing (configured selectors) | AVERAGE | `selector1,selector2` |
| Outbound IP on major list (Spamhaus DQS, Barracuda) · minor list (SpamCop, UCEProtect L1) | HIGH · WARNING | 2 checks in a row |
| Mail check fails / no data | AVERAGE | 2 checks · 30 min |
| Inbound / outbound probe not delivered | HIGH | nothing arrived for `{$INT.MAIL.E2E.TIMEOUT}` = 30 min (2 runs at 15 min) |
| Slow delivery | WARNING | > 600 s |
| Probe in junk folder | AVERAGE | – |
| Probe fails / no data | AVERAGE | 2 runs · 1 h |
| Exchange transport queue | AVERAGE / HIGH | > 100 / > 500 for 15 min |
| Exchange back pressure (events 15004/15006/15007) | AVERAGE | within 1 h |
| Exchange database not mounted · passive copy not healthy | DISASTER · HIGH | – |
| Exchange certificate expires · expired / not bound | AVERAGE · HIGH | < 14 days |
| Postfix deferred queue | AVERAGE | > 50 for 30 min |
| Postfix not running | HIGH | 3 checks |

Differences from the draft:
- Draft "2 of 2 external proxies": a Zabbix host has one proxy, so Basic uses **2 checks in a row** from one external proxy instead.
- MTA-STS is an item only (report). TLS-RPT is not checked.
- Exchange: the official `Microsoft Exchange Server 2016 by Zabbix agent active` is not linked (its agent availability item collides with
  `Windows by Zabbix agent active`). Exchange services are covered by the MON-SRV critical service list (step 5).
- Not in v1.0: probe for non-M365 mail (SMTP submission + IMAP), Exchange Online message trace, DMARC aggregate reports.

## 1. What the customer provides

Basic:
- List of mail domains.
- Outbound IPv4 addresses of their own mail servers / gateways (not needed for pure Microsoft 365).
- DKIM selectors if not M365 defaults (`selector1,selector2`).

Plus (contract: mailbox access = personal data processing, must be in the DPA):
- A **shared mailbox** for the probe (no licence), e.g. `zabbix-probe@acme.cz`, hidden from the address book.
- Global admin consent for the app **Integrit Mail Probe** and an Exchange admin for the RBAC scope (step 3).
- A transport rule / anti-spam exception so the probes are not quarantined (or agree that the probe tests the filter too).

Mail servers: MON-SRV agent on the server.

## 2. External proxy (once)

```
apt install bind9-dnsutils python3
install -m 0755 -o root int-mail-check.py /usr/lib/zabbix/externalscripts/
```
- The proxy must use **its own recursive resolver** (e.g. local `unbound`), not 8.8.8.8 / 1.1.1.1: public DNSBLs refuse queries from big
  public resolvers (refused answers are ignored by the script, so the blacklist check would silently find nothing).
- Outbound **TCP 25** must be open. Azure and most cloud providers block it: then set `{$INT.MAIL.SMTP.CHECK}=0` (MX port and STARTTLS
  triggers off) or move the external proxy.
- Spamhaus: commercial use needs a paid **DQS key**. Without it, leave `{$INT.MAIL.DQS.KEY}` empty (Barracuda, SpamCop, UCEProtect still run).

Test: `sudo -u zabbix /usr/lib/zabbix/externalscripts/int-mail-check.py integrit.cz selector1,selector2` → one JSON line with `"error": ""`.

## 3. Plus: app "Integrit Mail Probe" (once in Integrit, then per customer)

Integrit tenant (once):
1. Entra ID → App registrations → New: `Integrit Mail Probe`, **multi-tenant**. Add a client secret (24 months, calendar reminder).
2. **Do not** add `Mail.Send` / `Mail.ReadWrite` *application* permissions in Entra: they would cover every mailbox. Access is granted per
   mailbox with Exchange Online RBAC for Applications below.
3. Create the probe mailbox `zabbix-probe@<integrit domain>` (shared) and a second one `zabbix-selftest@<integrit domain>`.
4. Scope the app to these mailboxes (Exchange Online PowerShell, `<objectid>` = Enterprise application object ID in this tenant):
   ```
   New-ServicePrincipal -AppId <appid> -ObjectId <objectid> -DisplayName "Integrit Mail Probe"
   New-ManagementScope -Name "Integrit Mail Probe" -RecipientRestrictionFilter "PrimarySmtpAddress -eq 'zabbix-probe@integrit.cz' -or PrimarySmtpAddress -eq 'zabbix-selftest@integrit.cz'"
   New-ManagementRoleAssignment -App <appid> -Role "Application Mail.Send" -CustomResourceScope "Integrit Mail Probe"
   New-ManagementRoleAssignment -App <appid> -Role "Application Mail.ReadWrite" -CustomResourceScope "Integrit Mail Probe"
   ```
5. Global macros (Administration → Macros): `{$INT.MAIL.E2E.APP.ID}`, `{$INT.MAIL.E2E.SECRET}` (Secret text), `{$INT.MAIL.E2E.PROBE.TENANT}`
   (Integrit tenant ID), `{$INT.MAIL.E2E.PROBE.MAILBOX}` = `zabbix-probe@<integrit domain>`.

Per customer:
1. Admin consent: `https://login.microsoftonline.com/<customer tenant>/adminconsent?client_id=<appid>` (creates the Enterprise application).
2. The four commands of step 4 in the **customer** tenant, scope filter = the customer probe mailbox only.
3. RBAC changes need up to 2 h to apply. Check: `Test-ServicePrincipalAuthorization -Identity <appid> -Resource zabbix-probe@acme.cz`.

## 4. Hosts

**Domain host** (one per domain): name `MAIL <domain>`, customer host group + `Services/MON-MAIL`, tags per Part 3 (`service=MON-MAIL`),
monitored by the **external proxy**, no interface needed. Link `INT MON-MAIL Basic` (+ `INT MON-MAIL Plus`). Macros:

| Macro | Value |
|---|---|
| `{$INT.MAIL.DOMAIN}` | `acme.cz` |
| `{$INT.MAIL.OUTBOUND.IPS}` | `198.51.100.10,198.51.100.11` or empty |
| `{$INT.MAIL.DKIM.SELECTORS}` | only if not `selector1,selector2`; empty = no DKIM check |
| `{$INT.MAIL.SPF.CHECK}` / `{$INT.MAIL.DMARC.CHECK}` | `0` if the domain already has these alerts from MON-DNS |
| `{$INT.MAIL.DQS.KEY}` | set once as a **global** macro |
| Plus: `{$INT.MAIL.E2E.CUSTOMER.TENANT}` | `acme.onmicrosoft.com` or tenant ID |
| Plus: `{$INT.MAIL.E2E.CUSTOMER.MAILBOX}` | `zabbix-probe@acme.cz` |

**Self-test host** (once): `MAIL integrit self-test`, link only `INT MON-MAIL Plus`, `{$INT.MAIL.E2E.CUSTOMER.TENANT}` = Integrit tenant,
`{$INT.MAIL.E2E.CUSTOMER.MAILBOX}` = `zabbix-selftest@<integrit domain>`. If Integrit's own mail breaks, this host fires too.
On each customer domain host add **host-level dependencies** (Data collection → Hosts → host → Triggers → trigger → Dependencies) of both
"not delivered" triggers on the self-test host's "Inbound mail to ... not delivered" trigger, and on the customer's MON-M365 Exchange Online
service health trigger. Verify on the first pilot customer that Zabbix 7.0.31 saves dependencies on template-inherited triggers; if not,
use an action condition instead (suppress when the self-test problem is open).

**Exchange server:** link `INT MON-MAIL Exchange`. Copy the `.ps1` and `.conf` (Files table), `Restart-Service "Zabbix Agent 2"`.
Optional `{$INT.EXCH.DB.NOT_MATCHES}` = regex of recovery / test databases.

**Postfix server:** link `INT MON-MAIL Postfix`. Copy the script and `.conf`, `systemctl restart zabbix-agent2`.

## 5. MON-SRV service list on mail servers

Exchange: add `MSExchangeTransport|MSExchangeFrontEndTransport|MSExchangeIS|MSExchangeServiceHost|MSExchangeRepl|W3SVC` to
`{$INT.SERVICE.CRIT.MATCHES}` and also append them inside `{$SERVICE.NAME.NOT_MATCHES}` so the official discovery does not alert twice (MON-SRV INSTALL step 4). Postfix: the master process
is checked by this template; do not add `postfix` to the MON-SRV Linux list as well.

## 6. Import

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

Import `template_int_mon_mail_domain.yaml` and `template_int_mon_mail_servers.yaml` separately with the same boxes.

## 7. Verify

1. Basic: Latest data of the domain host after 5 min: `Mail: Check error` empty, `Mail: MX records` ≥ 1, `Mail: MX answering SMTP` ≥ 1,
   `Mail: SPF valid` = 1, `Mail: DMARC policy` matches `dig +short TXT _dmarc.<domain>`. Wrong selector test: set `{$INT.MAIL.DKIM.SELECTORS}`
   to `selector1,nonexist` → AVERAGE "DKIM selector missing" after the next check; put it back.
2. Plus: Test the item on the host (Latest data → `Mail flow: Probe raw` → Execute now, twice 15 min apart). The second run must show
   `in_found` 1 and `out_found` 1 with latencies in seconds. Errors name the failing Graph call (403 = RBAC scope not active yet).
   The probe mails are deleted permanently by the next run; nothing stays in Deleted Items.
3. Exchange: `zabbix_agent2.exe -c "C:\Program Files\Zabbix Agent 2\zabbix_agent2.conf" -t int.exch.db` → JSON list of database copies
   (needs up to 30 s: the Exchange snap-in loads). Latest data: `Exchange DB <name>: Copy OK` = yes for every database.
4. Postfix: `sudo -u zabbix /usr/local/lib/integrit/zabbix/int-postfix-queue.sh` → `{"active":0,"deferred":0,...}`.

Not tested in the build environment: the PowerShell script (no Exchange) and the Graph probe against a real tenant (logic tested with a
mock). Test both on the first customer before rollout.
