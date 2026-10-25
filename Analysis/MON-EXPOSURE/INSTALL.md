# MON-EXPOSURE: external attack surface: installation

Version 1.0 · Zabbix 7.0.31. Draft reference: section 5.6.12.

| Part | Where | How often |
|---|---|---|
| `INT MON-EXPOSURE Public IP` quick port checks | one host per customer public IP, monitored by the **external proxy** | every 15 min |
| Same template, weekly full scan | **dedicated Integrit scan VM** (not a proxy) → `zabbix_sender` → trapper item | weekly, Sunday night |
| `INT MON-EXPOSURE KEV feed` | once, on the Zabbix server host | daily |

**Only scan IPs listed in a signed customer consent** (contract annex with the IP list and scan window). Scanning without it is a legal
and contractual risk. This is not a penetration test or an authenticated vulnerability scan.

## Files

| File | Where |
|---|---|
| `template_int_mon_exposure.yaml` | Zabbix import |
| `scanner/int-exposure-scan.py` | scan VM: `/usr/local/lib/integrit/int-exposure-scan.py` (0755, root) |
| `scanner/exposure.json.example` | scan VM: `/etc/integrit/exposure.json` (0600, root), fill in |
| `scanner/int-exposure-scan.service`, `.timer` | scan VM: `/etc/systemd/system/` |

## Triggers

| Trigger | Severity | Default |
|---|---|---|
| RDP / SMB / NetBIOS open to the internet | DISASTER | 2 checks in a row (15 min) |
| Risky service reachable (FTP, Telnet, RPC, SQL, VNC, WinRM, admin / VPN panels 8080/8443/4443/10443/9443, NFS, Redis, ...) | HIGH | 2 checks in a row |
| New open ports outside the approved baseline (weekly scan) | AVERAGE | `{$INT.EXP.BASELINE}` = 80,443 |
| SSL / TLS 1.0 / 1.1 offered · weak cipher grade | WARNING | grade worse than B |
| Scan failed · not completed for 8 days | WARNING · AVERAGE | Integrit internal |
| New actively exploited vulnerability (CISA KEV) for a vendor used at customers | HIGH | manual close after fleet check |
| KEV download fails | WARNING | – |

Approved exposure (e.g. the FortiGate SSL VPN on 10443): `{$INT.EXP.ALLOWED:"10443"}=1` on that IP host.
Not in v1.0: automatic firmware-version-to-CVE matching per device (vendor PSIRT feeds), UDP checks in the 15-minute quick check
(UDP only in the weekly scan), SPF IP blacklists (MON-MAIL).

## 1. What the customer provides

- Signed consent annex: list of public IPs, scan window (default Sunday 01:30–04:00), contact for findings.
- Approved baseline of open ports per IP.
- Allow the Integrit scan VM IP and the external proxy IP in their IPS / geo-blocking (else results are blocked and their IPS alerts).

## 2. Scan VM (once, Integrit)

A small Linux VM outside customer networks with a **fixed public IP** published to customers. Check first that the hosting
provider allows outbound scanning (draft open point).
```
apt install nmap zabbix-sender python3
install -m 0755 int-exposure-scan.py /usr/local/lib/integrit/
install -m 0600 exposure.json.example /etc/integrit/exposure.json     # then edit
cp int-exposure-scan.service int-exposure-scan.timer /etc/systemd/system/
systemctl daemon-reload && systemctl enable --now int-exposure-scan.timer
```
`exposure.json`:
- `api_token`: API token of a user `zbx-exposure` (role type User, API allow list `template.get`, `host.get`; **Read** on `Customers/*`).
- `sender_target`: the external proxy that monitors the IP hosts, `host:10051`.
- `sender_args`: PSK settings if the IP hosts use PSK for "Connections from host" (recommended: identity `INT-EXPOSURE-SCANNER`,
  same PSK on every IP host's Encryption tab, "Connections from host: PSK").

Global macro `{$INT.EXP.SCANNER.IP}` = the scan VM's IP as seen by the external proxy (trapper "Allowed hosts").

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

**One host per public IP:** name `<CUST>-<SITE>-EXP-<WAN1>`, customer and site groups + `Services/MON-EXPOSURE`, tags per Part 3,
monitored by the **external proxy**, **Agent interface** with the public IP (no agent is used; the interface only gives the IP to the
simple checks and the scanner). Link `INT MON-EXPOSURE Public IP`. Macros:

| Macro | Example |
|---|---|
| `{$INT.EXP.BASELINE}` | `80,443,10443,u500,u4500` (u = UDP) |
| `{$INT.EXP.ALLOWED:"10443"}` | `1` (approved VPN portal, no HIGH) |

**KEV:** on the Zabbix server host link `INT MON-EXPOSURE KEV feed`. Adjust `{$INT.EXP.KEV.VENDORS}` to the vendors installed at
customers. The server needs HTTPS to www.cisa.gov (or set `{$INT.EXP.KEV.HTTP.PROXY}`).

## 5. Verify

1. Quick checks: Latest data on an IP host shows `Port 3389 (RDP) reachable from the internet` = closed (open on a test IP with a
   temporary port forward → DISASTER after 30 min).
2. Scanner dry run on the scan VM: `/usr/local/lib/integrit/int-exposure-scan.py --dry-run --host <host name>` prints the
   zabbix_sender line with JSON. Then without `--dry-run`: Latest data → `Scan: open TCP ports` filled, `Scan: error` empty.
3. KEV: Execute now on `KEV: raw`; `KEV: download error` empty.
4. Monthly report: `Scan: open TCP ports` / `Scan: services` history (400 days) = the exposure table per IP, usable as NIS2 evidence.

Scanner tested with simulated nmap output only; run the dry run on the first customer before enabling the timer.
