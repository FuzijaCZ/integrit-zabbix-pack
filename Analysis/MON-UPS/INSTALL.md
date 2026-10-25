# MON-UPS: UPS and power monitoring: installation

Version 1.0 · Zabbix 7.0.31 · official templates `release/7.0` (commit 362508f). Draft reference: section 4.8.

## Which template

| UPS | Template | Interface |
|---|---|---|
| APC with Network Management Card (NMC 2/3) | `INT MON-UPS APC` (links official `APC UPS by SNMP`) | SNMP |
| Eaton, Legrand, Socomec, Riello, CyberPower, Vertiv… with network card (RFC 1628 UPS-MIB) | `INT MON-UPS Generic UPS-MIB` | SNMP |
| Any UPS on USB only, connected to a Linux server | `INT MON-UPS NUT` on that server's MON-SRV host | agent 2 active |

The official APC model-specific templates (Smart-UPS 2200 RM, SRT 5000, …) are not needed: `APC UPS by SNMP` covers all NMC models.
USB UPS on a Windows server (PowerChute / vendor software) is not covered in v1.0. Fit a network card, or connect the USB cable to a Linux server with NUT.

## Files

| File | Purpose |
|---|---|
| `template_int_mon_ups_apc.yaml` | `INT MON-UPS APC` |
| `template_int_mon_ups_generic.yaml` | `INT MON-UPS Generic UPS-MIB` |
| `template_int_mon_ups_nut.yaml` | `INT MON-UPS NUT` |
| `linux/int_mon_ups.conf` | UserParameter for NUT → `/etc/zabbix/zabbix_agent2.d/` |

## Triggers

| Trigger | Severity | Default |
|---|---|---|
| UPS on battery | HIGH | longer than `{$INT.UPS.ONBATT.DELAY}`=1m (APC: official AVERAGE fires immediately as well) |
| On battery and runtime below required | DISASTER | `{$INT.UPS.RUNTIME.MIN}`=10m (**set per UPS from the customer requirement**) |
| Battery low while on battery | DISASTER | battery status low/depleted (NUT: `OB LB`) |
| Runtime at current load below required (on mains) | HIGH | runtime < `{$INT.UPS.RUNTIME.MIN}` for 15 min |
| Battery needs replacement | HIGH | APC official / NUT `RB` / generic: via "active alarms" WARNING |
| Self-test failed | HIGH | APC `upsAdvTestDiagnosticsResults` / UPS-MIB `upsTestResultsSummary` |
| Output load high | HIGH | > 90 % for 15 min (APC: official trigger with `{$UPS.OUTPUT.MAX.WARN}`=90) |
| Output load sustained | WARNING | > 80 % for 1 h |
| Battery older than 4 years | WARNING | APC: NMC "last replace date"; generic: `{$INT.UPS.BATTERY.INSTALLED}`=YYYYMMDD on the host |
| UPS unreachable | AVERAGE (generic, NUT) / WARNING (APC official "No SNMP data collection") | 5 min |
| Output off / on bypass (generic) | HIGH / AVERAGE | output source none / bypass |
| APC official extras | as official | input voltage/frequency out of range, battery temperature, bypass states, external sensors |

Notes:
- Correlation (draft 4.8 point 6): "UPS on battery" followed by "site unreachable" (MON-NET) is a power outage. The UPS host
  belongs to the site, so its triggers are suppressed by the site gateway dependency from MON-NET once that is built.
- SNMP traps are not used in v1.0: polling every 1 min detects on-battery within 1–2 min, which is enough for alerting.
- Controlled shutdown is a separate service (SRV-SHUTDOWN, draft 5.6.4). Monitoring does not shut anything down.

## 1. What the customer provides

- Network card IP in the management VLAN, reachable from the site proxy (UDP 161).
- Required runtime per UPS (minutes the protected equipment must run on battery).
- Battery install/replace date (APC: set it on the NMC; others: give it to Integrit).
- For USB UPS: which Linux server the cable goes to.

## 2. Prepare the device

**SNMP (APC NMC, other cards):** enable SNMPv3, user `zabbix`, security level **authPriv** (SHA / AES), read-only, access limited to the
site proxy IP. Disable SNMPv1 and default communities. Only if the card cannot do v3: SNMPv2c with a non-default community, restricted to the proxy IP.
APC: also set **Battery → Last replacement date** and enable the scheduled self-test (e.g. every 14 days).

**NUT (USB):** on the Linux server

```bash
apt install nut           # RHEL: dnf install nut
# /etc/nut/ups.conf:  [ups]  driver = usbhid-ups  port = auto
# /etc/nut/nut.conf:  MODE=standalone
systemctl enable --now nut-server
upsc ups@localhost        # must print battery.charge, ups.status, ...
install -m 0644 int_mon_ups.conf /etc/zabbix/zabbix_agent2.d/ && systemctl restart zabbix-agent2
```

## 3. Import the templates

**Data collection → Templates → Import**, each YAML file:

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

## 4. Configure the host (SNMP UPS)

- Host name `<CUST>-<SITE>-UPS01`, groups `Customers/<CUST>/<SITE>` + `Services/MON-UPS`, monitored by `PXY-<CUST>-<SITE>`.
- Interface **SNMP**, IP of the card, port 161, version SNMPv3, security name `zabbix`, authPriv, SHA/AES, passphrases.
- Template `INT MON-UPS APC` **or** `INT MON-UPS Generic UPS-MIB`.
- Tags `customer`, `site`, `managed`, `tier`, `contract`.
- Macros: `{$INT.UPS.RUNTIME.MIN}` = required runtime (e.g. `15m`); generic only: `{$INT.UPS.BATTERY.INSTALLED}` = `20240315`.

NUT: on the existing MON-SRV Linux host, link `INT MON-UPS NUT`; set `{$INT.UPS.NUT.NAME}` if the UPS is not called `ups`, and `{$INT.UPS.RUNTIME.MIN}`.

## 5. Verify

1. SNMP availability icon green within 2 min. Latest data: battery capacity/charge, runtime (in minutes/hours), load, output status/source.
2. APC: `INT: Battery last replaced (YYYYMMDD)` shows a date, e.g. `20230610` (otherwise the NMC date is empty; set it).
3. `INT: Self-test result` (APC) / `Self-test result` (generic) has a value within 1 h.
4. Real test (agree with the customer, protected equipment stays on battery): switch off the UPS input breaker for 2 min.
   Within 1 min you get official AVERAGE (APC), after 1 min more INT HIGH "UPS is on battery". Restore power, both resolve.
   Without a power test: temporarily set `{$INT.UPS.RUNTIME.MIN}` higher than the current runtime: HIGH "runtime at current load is below ..."
   appears within 15 min. Remove the macro afterwards.
