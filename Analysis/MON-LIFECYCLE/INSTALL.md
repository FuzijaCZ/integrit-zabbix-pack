# MON-LIFECYCLE: lifecycle, warranty, end of support and renewals: installation

Version 1.0 · Zabbix 7.0.31. Draft reference: section 5.6.5.

Mostly report data with a few date-based alerts. Recommended as part of the managed packages rather than a separate item.

| Template | Linked on |
|---|---|
| `INT MON-LIFECYCLE Asset` | any monitored asset host (server, NAS, firewall, switch, hypervisor), next to its other templates |
| `INT MON-LIFECYCLE Renewals` | one host per customer: `<CUST> Renewals` (no interface), the customer's renewal calendar |

Both are daily Script items (run on the host's proxy, no agent, no internet access needed).

## Files

| File | Where |
|---|---|
| `template_int_mon_lifecycle.yaml` | Zabbix import |

## Triggers

| Trigger | Severity | Default |
|---|---|---|
| Product out of vendor support | AVERAGE | end of support passed |
| Product reaches end of support soon | WARNING | < 180 days |
| Hardware warranty ends soon / ended | INFO | < 60 days (report) |
| Security subscription ends soon / ended | AVERAGE | < 30 days |
| Vendor support contract ends soon / ended | WARNING | < 60 days |
| Renewal expires | WARNING / AVERAGE / HIGH | < 30 / < 14 / < 7 days (chained); expired HIGH |
| Lifecycle data invalid · renewal calendar not evaluated | INFO | wrong date / product |

Per-entry renewal thresholds with macro context, e.g. `{$INT.LC.RENEW.WARN:"Veeam B&R licence"}=60`.
Not in v1.0: Dell / Lenovo warranty APIs (needs Integrit registration at Dell TechDirect / Lenovo), firmware age vs latest.

## Built-in lifecycle table (end of extended vendor support, as of 2026-10)

| Product (`{$INT.LC.PRODUCT}`) | End | Product | End |
|---|---|---|---|
| Windows Server 2012 / 2012 R2 | 2023-10-10 | SQL Server 2014 | 2024-07-09 |
| Windows Server 2016 | 2027-01-12 | SQL Server 2016 | 2026-07-14 |
| Windows Server 2019 | 2029-01-09 | SQL Server 2017 | 2027-10-12 |
| Windows Server 2022 | 2031-10-14 | SQL Server 2019 | 2030-01-08 |
| Windows Server 2025 | 2034-11-14 | SQL Server 2022 | 2033-01-11 |
| Windows 10 | 2025-10-14 | Exchange 2013 | 2023-04-11 |
| Windows 10 LTSC 2019 | 2029-01-09 | Exchange 2016 / 2019 | 2025-10-14 |
| Windows 10 LTSC 2021 | 2027-01-12 | VMware ESXi 7.0 | 2025-10-02 |
| Ubuntu 20.04 / 22.04 / 24.04 | 2025-05-31 / 2027-06-01 / 2029-06-01 | VMware ESXi 8.0 | 2027-10-11 |
| Debian 11 / 12 (LTS) | 2026-08-31 / 2028-06-30 | RHEL, Rocky, AlmaLinux 8 / 9 | 2029-05-31 / 2032-05-31 (RHEL 7: 2024-06-30) |

Ubuntu dates are end of standard support (Ubuntu Pro / ESM extends them; if the customer has Pro, set `{$INT.LC.EOS.DATE}`).
The table is in the Script item of the template. Owner: one person at Integrit, quarterly review; after a change re-import the template
(Items: Update existing TICK). Anything not in the table: set `{$INT.LC.EOS.DATE}` on the host.

## 1. What the customer provides

- Purchase / warranty data of servers, NAS, firewalls, switches (or Integrit reads it from the vendor warranty portals by serial number).
- Contracts and invoices for subscriptions, licences, support contracts and domain registrations.

## 2. Import

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

## 3. Hosts

**Asset hosts:** link `INT MON-LIFECYCLE Asset` and set the macros that apply (dates `YYYY-MM-DD`, empty = not tracked):

| Macro | Example |
|---|---|
| `{$INT.LC.PRODUCT}` | `Windows Server 2019` (exactly as in the table) |
| `{$INT.LC.EOS.DATE}` | `2027-12-31` only for products not in the table (Synology DSM, firewall firmware train, ...) |
| `{$INT.LC.WARRANTY.END}` | `2027-03-31` |
| `{$INT.LC.SUBSCRIPTION.END}` | `2027-05-14` (firewall security bundle; FortiGate licences are also read live by MON-NET) |
| `{$INT.LC.SUPPORT.END}` | `2027-02-28` |

Tip: put the macros on the host in the onboarding tool (draft 3.1.5) so they come from the customer register, not typed by hand.

**Renewals host** (one per customer): name `<CUST> Renewals`, customer group + `Services/MON-LIFECYCLE`, tags per Part 3, monitored by the
customer's site proxy or the external proxy, no interface. Link `INT MON-LIFECYCLE Renewals`. Macro:
```
{$INT.LC.RENEWALS}  Veeam B&R licence|2027-02-28;ESET PROTECT Entry|2027-01-15;FortiGuard UTP FGT-PRG|2027-05-14;Synology support NAS01|2026-12-20;acme.cz domain|2026-12-01;Pohoda maintenance|2027-03-31
```
Labels without apostrophes; entries separated by `;`.

## 4. Verify

1. Asset host → Latest data → `Lifecycle raw` → Execute now: `Lifecycle: End of vendor support in` shows days (Windows Server 2016 on
   2026-10-25 = 79 d → WARNING). `Lifecycle: Configuration error` empty.
2. Renewals host → Discovery → Execute now on `Renewals raw`: one `Renewal <label>: Days left` item per entry.
3. Report: the monthly report sorts all `int.lc.*.days` and `int.lc.renew.days[*]` items per customer = the lifecycle table with a
   12-month budget outlook (draft 5.6.5 point 7).
