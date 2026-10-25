# MON-MDM: Intune device compliance: installation

Version 1.0 · Zabbix 7.0.31. Draft reference: section 5.6.13.

`INT MON-MDM Intune` is linked on the customer's **MON-M365 tenant host** (external proxy, same `{$MS365.*}` credentials of the
Integrit Monitoring read app). Aggregated per tenant: counts are items, device lists are text (opdata and report). Per-device
problems only for devices in the "critical" Intune category. Draft recommendation: sell with MON-EPS as "Endpoint Plus".

## Files

| File | Where |
|---|---|
| `template_int_mon_mdm.yaml` | Zabbix import |

## Triggers

| Trigger | Severity | Default |
|---|---|---|
| Devices non-compliant | AVERAGE | > 5 devices or > 10 % |
| Devices not encrypted (Windows / macOS, active) | HIGH | > 0 |
| Critical device not encrypted or inactive | HIGH | category `Critical` |
| Devices inactive | WARNING | > 5 devices without sync for 30 days |
| Devices on an OS below minimum | WARNING | Windows build < 26100 (11 24H2), iOS < 17, Android < 13, macOS < 14 |
| Intune certificate / NDES connector not healthy | HIGH | – |
| Checks fail / no data | AVERAGE | 2 runs · 3 h |

Hourly. Problems resolve automatically when the counts go back under the thresholds.
Not in v1.0: Windows Update for Business reports (need Log Analytics), Autopilot profile failures, required-app install failures
(report later).

## 1. What the customer provides

- Intune in use (Business Premium, E3, E5) and admin consent for the extra permissions (step 2).
- Which devices are critical: create the Intune **device category** `Critical` and assign it (Intune → Devices → device → Properties).
- Acceptable inactivity (default 30 days) and minimum OS versions if different.

## 2. Permissions of the Integrit Monitoring (read) app

Graph application permissions, then re-consent in the customer tenant:
`DeviceManagementManagedDevices.Read.All`, `DeviceManagementConfiguration.Read.All`, `DeviceManagementServiceConfig.Read.All`.

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

On the MON-M365 tenant host: link `INT MON-MDM Intune`, add group `Services/MON-MDM`. Optional host macros:
`{$INT.MDM.NONCOMPLIANT.MAX}`, `{$INT.MDM.INACTIVE.DAYS}`, `{$INT.MDM.WIN.BUILD.MIN}` (19045 if the customer pays Windows 10 ESU),
`{$INT.MDM.CRITICAL.CATEGORY}`.

Keep the minimum OS macros current (template defaults as of 2026-10; review with the MON-LIFECYCLE table each quarter).

## 5. Verify

1. Latest data → `Intune devices raw` → Execute now: `Graph: errors` empty, `Devices: total` = Intune → Devices → All devices.
2. `Devices: not encrypted list` matches Intune → Devices → Monitor → Encryption report.
3. `Graph: optional check errors` showing an HTTP 400/404 for connectors is fine when the customer has no certificate connector.

Tested with mocked Graph responses only; verify the counts against the Intune portal on the first tenant.
