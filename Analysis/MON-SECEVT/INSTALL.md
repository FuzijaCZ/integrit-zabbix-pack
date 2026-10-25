# MON-SECEVT: basic security events on servers: installation

Version 1.0 · Zabbix 7.0.31. Draft reference: section 5.6.11.

| Template | Linked on |
|---|---|
| `INT MON-SECEVT Windows` | Windows member servers, next to `INT MON-SRV Windows` (not on DCs: MON-AD covers privileged groups and lockouts there) |
| `INT MON-SECEVT Linux` | Linux servers, next to `INT MON-SRV Linux` |

**Not a SIEM / SOC:** no log archive, no correlation, no 24/7 investigation. This must be in the customer text.
For NIS2 log retention a log platform (Wazuh, Sentinel, Graylog) is needed (draft variants).

## Files

| File | Where |
|---|---|
| `template_int_mon_secevt.yaml` | Zabbix import |
| `windows/int_mon_secevt.ps1` | `C:\Program Files\Zabbix Agent 2\scripts\int_mon_secevt.ps1` |
| `windows/int_mon_secevt.conf` | `C:\Program Files\Zabbix Agent 2\zabbix_agent2.d\int_mon_secevt.conf` |
| `linux/int-secevt.sh` | `/usr/local/lib/integrit/zabbix/int-secevt.sh` (0755, root) |
| `linux/int_mon_secevt.conf` | `/etc/zabbix/zabbix_agent2.d/int_mon_secevt.conf` |

## Triggers

"manual" = the problem stays open until someone closes it (Problems → Update → Close problem) after checking it against a ticket.

| Trigger | Severity | Close |
|---|---|---|
| Security log cleared (1102) · any event log cleared (System 104) | DISASTER | manual |
| Member added to a privileged / local admin / RDP group (4728/4732/4756) | HIGH | manual |
| RDP logon from a public IP (LocalSessionManager 21/25) | HIGH | manual |
| Defender malware detection (1116/1117) | HIGH | manual |
| Defender real-time protection disabled (5001) | HIGH | auto on 5000 |
| Failed logons (4625) | AVERAGE / HIGH | > 20 / > 100 in 5 min, auto |
| Local user created (4720) · audit policy changed (4719) · new service (7045, allow-list) | AVERAGE | manual |
| Scheduled task created (4698, allow-list) | WARNING | manual |
| Linux: SSH failures | AVERAGE / HIGH | > 20 / > 100 in 5 min |
| Linux: SSH logon from a public IP (not allowed) · sudo to root by an unexpected user · /etc/passwd or /etc/group changed | AVERAGE | manual |

The official Linux template (inside MON-SRV) also raises an INFO "/etc/passwd has been changed"; MON-SECEVT adds the AVERAGE
manual-close problem with its own checksum item (md5, to avoid a duplicate key).

Not in v1.0: Windows account lockouts on member servers (DC event, MON-AD), auditd log cleared (root-only log), Linux 4698-style
cron changes.

## 1. What the customer provides

- Approval of the audit policy GPO (step 2) and a larger Security log.
- On-call expectation for DISASTER security events outside working hours (draft open point: most SMB customers expect a phone call).
- A ticket for every planned admin change (new admin, new service), so manual problems can be closed quickly.

## 2. Windows audit policy (GPO, Integrit baseline)

Without it most events are never written. Create GPO `INT Audit baseline` linked to the servers' OU:

Computer Configuration → Policies → Windows Settings → Security Settings →
- Local Policies → Security Options → **Audit: Force audit policy subcategory settings** = Enabled
- Advanced Audit Policy Configuration → Audit Policies:

| Category | Subcategory | Setting |
|---|---|---|
| Account Management | Security Group Management | Success |
| Account Management | User Account Management | Success, Failure |
| Logon/Logoff | Logon | Success, Failure |
| Logon/Logoff | Account Lockout | Failure |
| Object Access | Other Object Access Events | Success (4698 scheduled tasks) |
| Policy Change | Audit Policy Change | Success |
| System | Security System Extension | Success |

- Event Log → **Maximum security log size** = 524288 KB (512 MB), retention "Overwrite events as needed".

Check on a server: `auditpol /get /category:*`.

## 3. Agent files

Windows: copy the `.ps1` and `.conf`, `Restart-Service "Zabbix Agent 2"`. The agent runs as LocalSystem and can read the Security log.

Linux:
```
install -m 0755 -o root int-secevt.sh /usr/local/lib/integrit/zabbix/
cp int_mon_secevt.conf /etc/zabbix/zabbix_agent2.d/
usermod -aG systemd-journal zabbix          # systems logging to /var/log/auth.log or /var/log/secure: usermod -aG adm zabbix
systemctl restart zabbix-agent2
```

## 4. Import

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

## 5. Hosts

Link the template, add group `Services/MON-SECEVT`. Tune per host only when needed:

| Macro | Use |
|---|---|
| `{$INT.SECEVT.SERVICE.REGEX}` / `{$INT.SECEVT.TASK.REGEX}` | add the customer's regular software (RMM, line-of-business app updaters) inside the `(?:...)` list |
| `{$INT.SECEVT.RDP.PUBLIC.REGEX}` | if a VPN hands out public addresses, add them as another `(?!...)` |
| `{$INT.SECEVT.FAILED.WARN}` / `.HIGH` | RDS / terminal servers with many users: e.g. 50 / 200 |
| Linux `{$INT.SECEVT.SUDO.USERS}` | `root,asmir,deploy` |
| Linux `{$INT.SECEVT.SSH.ALLOW}` | `203.0.113.10,198.51.100.` (Integrit office IPs, customer admin IPs) |

Servers with ESET or another AV (Defender passive): disable the item `Defender: Real-time protection state` on that host.

## 6. Verify

1. Windows: `zabbix_agent2.exe -c "C:\Program Files\Zabbix Agent 2\zabbix_agent2.conf" -t int.secevt.failed[5]` →
   `{"count":0,"accounts":"","ips":""}`.
2. Windows test (with the customer's approval, then close the problems manually):
   - `net localgroup Administrators test-int /add` after `net user test-int Passw0rd!x /add` → AVERAGE "Local user account created" and HIGH
     "Member added to a privileged group" within 1 min. Remove the user.
   - 25 wrong passwords with `runas /user:test-int cmd` → AVERAGE "Many failed logons" within 5 min.
3. Linux: `sudo -u zabbix /usr/local/lib/integrit/zabbix/int-secevt.sh 5 root ''` → JSON; 25 failed `ssh wronguser@server` →
   AVERAGE "Many SSH authentication failures".

Not tested in the build environment: the PowerShell script and the localized (Czech) Windows event texts. The group regex contains EN
and CZ names; verify on the first Czech server.
