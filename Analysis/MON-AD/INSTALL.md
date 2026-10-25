# MON-AD: Active Directory and domain controllers: installation

Version 1.0 · Zabbix 7.0.31. Draft reference: section 5.6.7.

`INT MON-AD Domain controller` is linked on **every domain controller** (Windows Server 2016–2025) next to `INT MON-SRV Windows`.
No official Zabbix 7.0 AD template exists. Data comes from the DC's agent 2 (PowerShell, read-only) and from port checks run by the site proxy.

## Files

| File | Where |
|---|---|
| `template_int_mon_ad.yaml` | Zabbix import |
| `windows/int_mon_ad.ps1` | `C:\Program Files\Zabbix Agent 2\scripts\int_mon_ad.ps1` |
| `windows/int_mon_ad.conf` | `C:\Program Files\Zabbix Agent 2\zabbix_agent2.d\int_mon_ad.conf` |

## Triggers

| Trigger | Severity | Default |
|---|---|---|
| DC service stopped (NTDS, Netlogon, Kdc, DNS, DFSR, W32Time, ADWS) | HIGH | 3 checks |
| Replication from a partner failing | HIGH | ≥ 1 consecutive failure for 60 min, or last success > 3 h |
| SYSVOL / NETLOGON share missing | HIGH | 3 checks |
| SYSVOL DFS-R state not Normal | HIGH | state ≠ 4 |
| Clock offset to PDC | AVERAGE / HIGH | > 60 s / > 240 s |
| Domain SRV records not resolvable | HIGH | `_ldap._tcp.dc._msdcs.{$INT.AD.DOMAIN}`, 3 checks |
| LDAP / LDAPS / Kerberos port not reachable from proxy | HIGH | 3 min (LDAPS: `{$INT.AD.LDAPS.CHECK}=0` if the DC has no certificate) |
| AD not backed up | HIGH | > 7 days (dSASignature of the domain NC) |
| Privileged group membership changed | AVERAGE (HIGH for Enterprise / Schema Admins) | any change; **stays open until closed manually** |
| krbtgt password old | WARNING | > 180 days |
| Account lockout surge | WARNING | > 10 new lockouts in 15 min |
| dcdiag failed tests / dcdiag did not run | AVERAGE | daily |
| Directory Service / DFS Replication problem events | AVERAGE | listed event IDs within 1 h |

Domain-wide checks (groups, krbtgt, lockouts) run only on the **PDC emulator**. The other DCs return nothing, so problems are not duplicated.
When the PDC role moves, the new PDC reports. The group member history lives on that DC's host (item history 365 days).

Privileged groups checked: Domain Admins, Enterprise Admins, Schema Admins, Administrators, Account Operators, Backup Operators,
Server Operators, Print Operators, DnsAdmins, Group Policy Creator Owners.

Not in v1.0: FSMO holder availability (covered indirectly by replication / dcdiag), Entra Connect ADSync service (use the MON-SRV critical
service list: `ADSync`), counts of inactive / disabled accounts and "password never expires" admins (report section, later).

## 1. What the customer provides

- Approval of the Zabbix agent on DCs (security review, draft MON-SRV §10). The agent runs as LocalSystem and only reads AD; no admin rights needed.
- The AD domain DNS name.
- The change process for privileged groups, so group-change problems can be matched to tickets.
- An AD-aware backup (system state / Veeam AD-aware) if not already in place, otherwise "AD not backed up" fires.

## 2. Agent files (on every DC)

Copy `int_mon_ad.ps1` and `int_mon_ad.conf` as listed above, then `Restart-Service "Zabbix Agent 2"`. The ActiveDirectory PowerShell module is present on DCs.

On the DC's MON-SRV host:
- **Host interface:** add an **Agent** interface with the DC IP (used for the LDAP/LDAPS/Kerberos port checks from the site proxy).
- **MON-SRV service macros:** do **not** list DC services in `{$INT.SERVICE.CRIT.MATCHES}` (MON-AD covers them), but exclude them from the
  official all-services discovery so a stopped NTDS does not raise a second AVERAGE: append `|NTDS|Netlogon|Kdc|DNS|DFSR|W32Time|ADWS` inside the
  `^(?:...)$` of `{$SERVICE.NAME.NOT_MATCHES}` (see MON-SRV INSTALL step 4).

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

On each DC host: add group `Services/MON-AD`, link `INT MON-AD Domain controller`, set `{$INT.AD.DOMAIN}` (e.g. `acme.local`).
Optional: `{$INT.AD.LDAPS.CHECK}=0`, `{$INT.AD.GROUP.HIGH:"Domain Admins"}=1` if the customer wants Domain Admins changes as HIGH.

## 5. Verify

1. On the DC: `zabbix_agent2.exe -c "C:\Program Files\Zabbix Agent 2\zabbix_agent2.conf" -t int.ad.repl` → JSON list of partners;
   `-t int.ad.pdc` → `{"pdc":1,...}` on the PDC emulator, `{"pdc":0}` elsewhere.
2. Latest data: 7 `DC service ...` items = Running; `Replication <partner> ...` items per partner and naming context; `SYSVOL DFS-R state` = Normal;
   `Last AD backup age` matches `repadmin /showbackup`.
3. Group test (with the customer's approval): add a test user to `Backup Operators` → within 15 min AVERAGE "Membership of Backup Operators changed".
   Remove the user, then close both problems manually in Zabbix (Problems → Update → Close problem).
