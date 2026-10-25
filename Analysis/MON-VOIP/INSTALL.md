# MON-VOIP: PBX and VoIP (SIP check): installation

Version 1.0 · Zabbix 7.0.31. Draft reference: section 4.15. Scope decided 25 Oct 2026: **vendor-neutral SIP check only**.
PBX vendor APIs (3CX, FreePBX) follow later.

`INT MON-VOIP SIP endpoint` sends a SIP **OPTIONS** request (like a phone "ping") to a PBX, SBC or provider trunk endpoint and alerts when nothing
answers. Zabbix has no native SIP check, so the probe is a small Python script run by the proxy (`ExternalScripts`).

## Files

| File | Where |
|---|---|
| `template_int_mon_voip_sip.yaml` | Zabbix import |
| `externalscripts/int-sip-options.py` | on **every proxy** that runs SIP checks (site proxies and external proxies): `/usr/lib/zabbix/externalscripts/` |

## Which host, which proxy

| Endpoint | Host | Monitored by | `{$INT.SIP.PBX}` | Not answering |
|---|---|---|---|---|
| On-prem PBX (3CX, FreePBX, Yeastar, Grandstream, ...) | `<CUST>-<SITE>-PBX01`, interface = PBX LAN IP | site proxy | `1` | HIGH (DISASTER with `{$INT.TIER.CRITICAL}=1`) |
| Hosted / cloud PBX, provider SBC or trunk endpoint | `<CUST>-SIP-<name>`, interface = public FQDN/IP | external proxy | `0` | AVERAGE |

Host interface: type **Agent**, IP or DNS of the endpoint (only used as `{HOST.CONN}` target).

## Triggers

| Trigger | Severity | Default |
|---|---|---|
| Critical PBX does not answer SIP | DISASTER | 2 probes in a row without answer or with 5xx/6xx, `{$INT.TIER.CRITICAL}=1` |
| PBX does not answer SIP | HIGH | same, on-prem PBX |
| SIP endpoint does not answer from outside | AVERAGE | same, hosted / trunk endpoint |
| SIP response time | WARNING | > `{$INT.SIP.RTT.MAX}`=300 ms for 3 probes |

Any answer below 500 counts as "alive", including `401/403/404/405`. Many PBXs reject OPTIONS from unknown sources but still prove the SIP
stack works. Probe interval: 1 min.

Not in v1.0 (draft scope): trunk registration state, registered phone count, channel usage, licence expiry, toll-fraud indicators. They need
the PBX vendor API.

**Dependencies:** a PBX trunk problem during a WAN outage is suppressed by the site gateway / WAN dependency (MON-NET). Set it at host level:
`INT: PBX ... does not answer SIP` → depends on `<CUST>-<SITE>-GW01: INT: Site gateway is unreachable`.

## 1. What the customer provides

- PBX vendor, model, version (catalogue requirement) and the SIP port/transport (default UDP 5060; TLS 5061).
- Allow SIP OPTIONS from the site proxy IP (on-prem) or the Integrit external proxy IPs (hosted / SBC) in the PBX / SBC access list and firewall.
  Fail2ban-type protection on FreePBX / 3CX must whitelist these IPs, or it bans the probe.

## 2. Install the probe on the proxies

```bash
install -m 0755 int-sip-options.py /usr/lib/zabbix/externalscripts/int-sip-options.py
grep ^ExternalScripts /etc/zabbix/zabbix_proxy.conf     # default /usr/lib/zabbix/externalscripts
sudo -u zabbix /usr/lib/zabbix/externalscripts/int-sip-options.py <pbx-ip> 5060 udp
# → {"code": 200, "reason": "OK", "rtt_ms": 3.1, "error": ""}
```

Python 3.6+ standard library only (Debian 12 / Ubuntu 24.04 have it by default).

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

Groups `Customers/<CUST>/<SITE>` (or `Customers/<CUST>` for hosted) + `Services/MON-VOIP`, template `INT MON-VOIP SIP endpoint`, tags
`customer`, `site`, `managed`, `tier`, `contract`. Macros as needed: `{$INT.SIP.PBX}`, `{$INT.SIP.PORT}`, `{$INT.SIP.TRANSPORT}`, `{$INT.TIER.CRITICAL}`.

## 5. Verify

1. Latest data → `SIP: Response code` is a SIP code (200, 403, 404, ...), `SIP: Response time` in ms, `SIP: Error` empty.
2. Set `{$INT.SIP.PORT}` to an unused port (e.g. `5999`): after 2 min HIGH / AVERAGE "does not answer"; `SIP: Error` shows the reason. Revert.
