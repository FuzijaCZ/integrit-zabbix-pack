# PLATFORM: monitoring of the monitoring (Zabbix server, proxies, alerting, dead-man switch): installation

Version 1.0 · Zabbix 7.0.31. Draft reference: section 3.1.6.

| Template / object | On | What |
|---|---|---|
| `INT PLATFORM Zabbix server` | the Zabbix server host (`Integrit/Platform`) | official `Zabbix server health` + customer proxies not connected, failed / stuck notifications, heartbeat |
| `INT PLATFORM Zabbix proxy` | every proxy host (monitored by the proxy itself) | official `Zabbix proxy health` |
| Media type `INT Heartbeat` | Alerts → Media types | external dead-man switch ping |

## Files

| File | Where |
|---|---|
| `template_int_platform_zabbix.yaml` | Zabbix import (Data collection → Templates → Import) |
| `media_int_heartbeat.yaml` | Zabbix import (Alerts → Media types → Import) |

## Triggers

| Trigger | Severity | Default |
|---|---|---|
| Site `<SITE>` of `<CUST>` unreachable: proxy last seen | HIGH | > 300 s (tags `customer`, `site` from the proxy name `PXY-<CUST>-<SITE>`) |
| Proxy has never connected | WARNING | – |
| Notifications are failing | HIGH | ≥ 1 failed in the last hour |
| Notifications are stuck in the queue | HIGH | "not sent" for > 10 min, 5 min |
| Platform API self-check fails | HIGH | 2 runs |
| Platform heartbeat (always open) | INFO | drives the dead-man switch, never alerted to people |
| Official server / proxy health (caches, process utilisation, queue, wrong template, ...) | as official | official defaults |

The official server WARNING "Zabbix proxy last seen" is switched off (`{$ZABBIX.PROXY.LAST_SEEN.MAX}=999999999`) and replaced by the
INT HIGH trigger with customer and site tags.

## 1. Prerequisites

- The external heartbeat service: an account at a hosted heartbeat checker (healthchecks.io, Better Stack, Cronitor) or an Azure
  Function / Logic App. Create one check "Integrit Zabbix" with period **5 min**, grace **10 min**, alert channel = Integrit e-mail +
  SMS to the on-call phone. Copy its **https ping URL**.
- Proxies named `PXY-<CUST>-<SITE>` (draft 3.1.3). Other names are discovered with customer tag `INTEGRIT`.

## 2. API user for the self-check

1. Users → User roles → Create: `INT Selfcheck`, User type **Admin**, UI: nothing needed, **API access: Allow list** with methods
   `proxy.get`, `alert.get`, `item.get`. Actions: all unticked.
2. Users → User groups → Create `INT Selfcheck`: Frontend access **Disabled**, Host permissions: **Read** on `Customers/*` and
   `Integrit/*` (all groups with hosts).
3. Users → Users → Create `zbx-selfcheck` in that group with that role.
4. Users → API tokens → Create for `zbx-selfcheck`, no expiry (or 1 year + calendar reminder). Copy the token.

## 3. Import

Templates (`template_int_platform_zabbix.yaml`):

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

Media type (`media_int_heartbeat.yaml`): Media types → Import, **Update existing TICK, Create new TICK**.

## 4. Hosts

**Zabbix server host** (default `Zabbix server`, group `Integrit/Platform`): unlink the official `Zabbix server health` if linked
directly, link `INT PLATFORM Zabbix server`. Host macro `{$INT.ZBX.API.TOKEN}` = token from step 2 (type Secret text).
If the frontend is not on the server: `{$INT.ZBX.API.URL}` = `https://<frontend>/api_jsonrpc.php`.

**Proxy hosts** (one per proxy, group `Integrit/Platform`, monitored by **that proxy**): link `INT PLATFORM Zabbix proxy` and
`INT MON-SRV Linux` (agent on the proxy VM). Remove a direct link to `Zabbix proxy health` if present.

## 5. Dead-man switch

1. Users → Users → Create `heartbeat` (group without host permissions except **Read** on `Integrit/Platform`, no frontend access).
   Media tab: type `INT Heartbeat`, Send to = the ping URL from step 1, all severities, always active.
2. Alerts → Actions → Trigger actions → Create `INT Heartbeat`:
   - Conditions: Tag `scope` equals `heartbeat` **and** Host group equals `Integrit/Platform`.
   - Operations: default step duration **5m**; operation steps **1 – 0** (0 = repeat forever), send to user `heartbeat`, media `INT Heartbeat`.
   - Recovery / update operations: none.
3. **Every other action** (customer, NOC, on-call): add condition Tag `scope` **does not equal** `heartbeat`.
4. Wait 10 min: the external service shows a ping every 5 min. Test the switch: stop `zabbix-server` for 15 min in a maintenance
   window → the external service must alert Integrit.

## 6. Verify

1. Latest data on the server host: `Platform: API check error` empty; `Proxy <name>: Last seen` items for every proxy with values < 60 s.
2. Stop the `zabbix-proxy` service on a test proxy → after 5 min HIGH "Site ... of ... unreachable"; problem tags show customer and site.
3. Notification test: in a test user set an invalid e-mail media type password, trigger a test problem → "Notifications are failing".
4. Zabbix DB and config backup: monitor them with MON-BKP on the Zabbix server (draft 3.1.6).
