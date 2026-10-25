# MON-PRINT: printers and multifunction devices: installation

Version 1.0 · Zabbix 7.0.31. Draft reference: section 5.6.17.

`INT MON-PRINT Printer` is one generic template for printers / MFPs of any vendor (HP, Kyocera, Canon, Konica Minolta, Brother,
Ricoh, Xerox, Zebra label printers with Printer-MIB) over standard MIBs, polled by the site proxy. No official printer template
exists in Zabbix 7.0. Draft recommendation: sell inside the "site" package or where Integrit supplies the consumables.

## Files

| File | Where |
|---|---|
| `template_int_mon_print.yaml` | Zabbix import |

## Triggers

| Trigger | Severity | Default |
|---|---|---|
| Supply empty (toner, ink, drum, ...) | AVERAGE | ≤ 1 % |
| Supply low | WARNING (Integrit orders supplies) / INFO (customer orders) | < 10 %, `{$INT.PRINT.ORDER.BY.INTEGRIT}` |
| Printer error (jam, door open, no paper, service, tray missing, output full) | WARNING · AVERAGE on critical printers | 15 min |
| Printer unreachable in working hours | WARNING | 30 min, Mon–Fri 07:00–17:00 |
| Critical printer unreachable (any time) | HIGH | `{$INT.TIER.CRITICAL}=1` |

Supplies reporting "some remaining" without a percentage (-3) or unknown (-2) never alert. Waste toner containers are not alerted.
Monthly page counts: history of `Printer: page counter` (400 days) → report (monthly increase per device).
Not in v1.0: separate black / colour counters (vendor MIBs), prtAlertTable details, managed-print fleet tools (if the customer has a
managed print contract with a vendor, do not duplicate).

## 1. What the customer provides

- List of printers with location (and which are critical: label / logistics printers).
- Who orders consumables (customer or Integrit).
- SNMP enabled on the devices (read-only community, or SNMPv3 where supported), printers reachable from the site proxy.

## 2. Device settings

On each printer's web page: enable SNMP v1/v2c **read-only** with a non-default community (or SNMPv3 authPriv), disable SNMP write.
Restrict SNMP to the proxy IP where the device allows it. Disable deep sleep only if the customer wants 24/7 availability alerts.

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

Per device: `<CUST>-<SITE>-PRN-<name>`, customer / site groups + `Services/MON-PRINT`, tags per Part 3, **site proxy**, **SNMP
interface** with `{$SNMP_COMMUNITY}` (or v3). Link `INT MON-PRINT Printer`. Bulk creation: onboarding tool / host import (draft 3.1.5).

| Macro | When |
|---|---|
| `{$INT.PRINT.ORDER.BY.INTEGRIT}=1` | Integrit supplies the consumables (put it on the customer's host group via the onboarding tool) |
| `{$INT.TIER.CRITICAL}=1` | label / logistics printers (also host tag `tier=critical`) |
| `{$INT.PRINT.WORK.START}` / `.END` | other working hours (hhmmss) |
| `{$INT.PRINT.SUPPLY.NOT_MATCHES}` | supplies to ignore, e.g. `(?i)staple` |

## 5. Verify

1. Latest data: `Printer: status` = idle / printing; one `Supply <name>: level` item per toner / drum with the same % as the device
   web page; `Printer: page counter` = the device counter.
2. Open the front door for 16 min → WARNING "Printer ... has an error: door open"; close → resolves.
3. Devices where supplies show -3: the vendor does not report percentages over Printer-MIB (some inkjets); only "empty" from the
   error bits (`no toner` is not alerted by default: add it to `{$INT.PRINT.ERROR.REGEX}` for such models).

Tested logic: error-bit decoding against sample values; verify supply percentages on the first models of each vendor.
