# MON-CCTV: camera systems (NVR, cameras): installation

Version 1.0 · Zabbix 7.0.31. Draft reference: section 5.6.16.

| Template | Linked on | How |
|---|---|---|
| `INT MON-CCTV Hikvision NVR` | each Hikvision NVR / DVR | site proxy, ISAPI (HTTP digest), read-only user |
| `INT MON-CCTV Generic cameras` | the recorder / VMS host, or a per-site camera host | site proxy: ICMP + RTSP port per camera (any brand) |
| `INT MON-CCTV Hikvision camera` | optional, one host per important Hikvision camera | official `Hikvision camera by HTTP` |

**Not a security / alarm service:** recordings are not watched and video events are not evaluated. Must be in the customer text.

## Files

| File | Where |
|---|---|
| `template_int_mon_cctv.yaml` | Zabbix import |

## Triggers

| Trigger | Severity | Default |
|---|---|---|
| Recorder unreachable (ICMP) | HIGH | 5 min |
| Recorder disk not OK (failed / unformatted / error) | HIGH | 2 checks |
| Channel not recording | HIGH | no recording in the last 30 min, 2 checks (15 min interval); per channel `{$INT.CCTV.RECORD.EXPECTED:"<ch>"}=0` for motion-only |
| Camera channel offline (NVR) · camera offline (generic) | AVERAGE | 2 checks · 10 min |
| Retention below agreed days | AVERAGE | oldest recording < `{$INT.CCTV.RETENTION.DAYS}` − 1 |
| Retention above the GDPR maximum | WARNING | `{$INT.CCTV.RETENTION.MAX}` (0 = off) |
| Recorder clock off | WARNING | > 60 s |
| Recorder API checks fail | AVERAGE | 2 runs |
| Firmware changed | INFO | – |

Dependencies: channel, disk and API triggers depend on "Recorder unreachable". Add a host-level dependency of "Recorder unreachable"
on the site gateway / PoE switch trigger (MON-NET INSTALL step 4). Firmware with known vulnerabilities: MON-EXPOSURE KEV feed
(vendor Hikvision can be added to `{$INT.EXP.KEV.VENDORS}`).
Not in v1.0: Dahua, Axis, Synology Surveillance Station, Milestone (draft: next releases), RAID of the NVR, PoE port mapping.

## 1. What the customer provides

- Recorder IPs, camera list with locations (label | IP) for the generic check.
- **Agreed retention days** per site (from the customer's GDPR assessment) and the maximum allowed.
- Which channels record only on motion / schedule.
- A read-only user on the NVR (step 2) and a route from the site proxy into the camera VLAN for HTTP(S) / RTSP / ICMP only.

## 2. Recorder user (Hikvision)

NVR web → Configuration → System → User Management → Add: user `zabbix`, level **Operator** (or a custom role with only *Remote:
Playback / Search* and *Remote: Parameters Settings (view)*), strong password. Network → Advanced → Integration Protocol: **Enable
Hikvision-CGI / ISAPI**, authentication **digest**. Prefer HTTPS if the firmware supports it (`{$INT.CCTV.SCHEME}=https`,
`{$INT.CCTV.PORT}=443`).

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

NVR host: `<CUST>-<SITE>-NVR01`, customer / site groups + `Services/MON-CCTV`, tags per Part 3, **site proxy**, Agent interface with
the NVR IP (used by ICMP and as `{HOST.CONN}` for ISAPI; no agent). Link `INT MON-CCTV Hikvision NVR` (+ `Generic cameras` for IP
cameras reachable directly). Macros:

| Macro | Example |
|---|---|
| `{$INT.CCTV.USER}` / `{$INT.CCTV.PASSWORD}` | `zabbix` / secret |
| `{$INT.CCTV.RETENTION.DAYS}` | `14` |
| `{$INT.CCTV.RETENTION.MAX}` | `30` |
| `{$INT.CCTV.RECORD.EXPECTED:"5"}` | `0` (channel 5 records on motion only) |
| `{$INT.CCTV.CAMERAS}` | `Entrance\|10.0.50.21;Parking\|10.0.50.22` (type plain `|`) |

Cameras on the NVR's built-in PoE ports sit in the NVR's internal network and are not reachable from the proxy: for them the NVR
channel status is the check; do not list them in `{$INT.CCTV.CAMERAS}`.

## 5. Verify

1. Latest data → `Recorder: ISAPI raw` → Execute now: `Recorder: API error` empty, `Recorder: model` / `firmware` filled.
2. One `Channel N` item pair per camera channel; `recorded in the last window` = yes for continuously recording channels.
3. `Recorder: retention` ≈ the oldest day shown in the NVR playback calendar for channel 1.
4. Disconnect a test camera → after 2 runs AVERAGE "Camera channel N offline" (and HIGH "not recording" is suppressed by dependency).

ISAPI endpoints used: `/ISAPI/System/deviceInfo`, `/System/time`, `/ContentMgmt/Storage`, `/ContentMgmt/InputProxy/channels/status`,
`/ContentMgmt/search`. Tested against simulated responses only; older DVRs (analog channels) may not have InputProxy: then channels are
not discovered and only disks / retention / clock are checked. Verify on the first recorder.
