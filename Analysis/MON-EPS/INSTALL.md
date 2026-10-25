# MON-EPS: endpoint security (ESET): installation

Version 1.0 · Zabbix 7.0.31. Draft reference: section 4.13.

`INT MON-EPS ESET PROTECT Cloud` monitors one ESET PROTECT (Cloud) tenant through the **ESET Connect** public API.
One Zabbix host per customer tenant (`<CUST>-ESET`, external proxy group, no interface). No official Zabbix template exists.

**Design (draft 4.13): aggregate per tenant, detail on demand.** No Zabbix item per endpoint. Counts per tenant, and a problem per device only
for unresolved high-severity detections.

## Files

| File | Template |
|---|---|
| `template_int_mon_eps_eset.yaml` | `INT MON-EPS ESET PROTECT Cloud` |

## Triggers

| Trigger | Severity | Default |
|---|---|---|
| Unresolved high-severity detection on a device | HIGH | unresolved > `{$INT.ESET.DETECTION.MIN.AGE}`=1800 s (30 min) |
| Devices not connected | AVERAGE | > `{$INT.ESET.STALE.MAX.COUNT}`=5 devices or > `{$INT.ESET.STALE.MAX.PCT}`=10 % without sync for `{$INT.ESET.STALE.DAYS}`=7 days |
| Any detection in the last 24 h | INFO (report) | – |
| ESET Connect API error | AVERAGE | login / API failure |

Not in v1.0 (draft scope), because the ESET Connect device list used here has no stable field for them: protection disabled per device,
outdated detection engine, licence usage. They follow once the fields are verified on a real tenant. ESET PROTECT On-Prem (ODBC to the
console DB) and Microsoft Defender are not in v1.0.

Customer text must keep the catalogue limitation: **this is not a SOC/SIEM**. Detections are reported, not investigated. Out-of-hours handling
of HIGH detections is an open decision (draft 4.13 point 10).

## 1. What the customer provides / Integrit sets up

- ESET PROTECT Hub / ESET Business Account: create a **dedicated API user** (e.g. `zabbix-api@integrit.cz`) with **read-only** access and the
  **Integrations** (API) permission for the customer's company. If Integrit is an ESET MSP partner, one MSP-level API user can read all managed companies.
  In that case still create one Zabbix host per customer, with the same credentials.
- The data centre (region) of the tenant: the first part of the console URL, e.g. `eu.protect.eset.com` → `eu`.
- The customer's definition of "not connected" (catalogue requirement), if different from 7 days.

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

## 3. Host

`<CUST>-ESET`: groups `Customers/<CUST>` + `Services/MON-EPS`, monitored by the external proxy group, no interface, template
`INT MON-EPS ESET PROTECT Cloud`, tags `customer`, `managed`, `tier`, `contract`. Macros: `{$INT.ESET.USER}`, `{$INT.ESET.PASSWORD}` (secret),
`{$INT.ESET.REGION}`.

## 4. Verify (important on the first tenant)

1. Items → `ESET: Get data` → **Execute now**. Within 2 min `ESET: API error` is empty and `ESET: Devices` equals the number of computers
   in the ESET PROTECT console.
2. **Field check:** the script reads the ESET Connect fields `devices[].uuid/displayName/lastSyncTime` and
   `detections[].severityLevel/resolved/occurTime/deviceUuid`. Compare `ESET: Devices not connected` and `ESET: Unresolved detections` with the
   console. If they differ, look at the raw API answer (Data collection → Items → `ESET: Get data` → Test → Get value) and tell Integrit
   which field names the tenant returns.
3. Test detection: on a test PC, download the EICAR test file (`https://secure.eicar.org/eicar.com.txt`). ESET logs a detection; with a HIGH
   severity mapping the device problem appears after 30 min if not resolved. Mark it resolved in the console: the problem resolves on the next
   run (15 min).
