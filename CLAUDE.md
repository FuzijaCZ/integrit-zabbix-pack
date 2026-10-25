# Integrit Zabbix monitoring pack

Owner: Asmir, junior IT tech at integrit s.r.o. (Czechia).
Source of truth: `Integrit_Zabbix_Monitoring_Working_Draft.md` (Czech) in the repo root.
Platform: Zabbix 7.0.31 LTS, one multi-tenant server, active proxy per customer site.
Read Part 3 (tags customer/site/service/managed/tier, naming, macros, severity convention)
and the relevant Part 4/5 section before building each service.

## Scope and order (draft section 6.3)

1. MON-SRV (Windows + Linux)
2. MON-BKP (Veeam + e-mail parser)
3. MON-UPS
4. MON-NET
5. MON-LAN
6. MON-NAS (Synology, QNAP)
7. MON-VIRT (VMware, Proxmox, Hyper-V)
8. MON-M365
9. MON-EPS (ESET)
10. MON-WEB-FUNC
11. MON-VOIP
12. MON-CUSTOM
13. Wave A add-ons (Part 5): MON-HW, MON-DB, MON-AD, MON-MAIL, MON-ENV, MON-CERT

Out of scope: MON-WP, MON-DNS (done), MON-WEB basics.

## Rules

- Lean and actionable: monitor only what matters. No generic bloat.
- Never copy or edit official Zabbix templates. Wrap them as `INT <SERVICE-ID> <technology>`,
  link the official template, override macros, add only what is missing or better.
- Zabbix 7.0 only: no 7.2+ features. Export format `zabbix_export: version: '7.0'`.
- Each template: service tag, macros for every threshold, severities per draft 3.1.4,
  trigger dependencies, LLD with filters, unique UUIDv4 (32 hex, no dashes).
- Real values, no placeholders. If something needs Asmir's input, ask.
- Validate every YAML before delivery: parses, required fields, unique UUIDs and keys,
  trigger expressions reference `/<template name>/<existing key>`, no 7.2+ fields.
  Check names, keys and macros against the official templates on branch `release/7.0`
  at https://github.com/zabbix/zabbix/tree/release/7.0/templates
- Output per service in `Analysis/<SERVICE-ID>/`: template YAML(s), any agent scripts or
  UserParameter files, and `INSTALL.md` (what the customer provides; exact Zabbix import
  steps with which boxes to TICK and which to leave UNTICKED; how to verify it works).
- ONE service at a time. After each: commit and push, give a 5-line summary, list the
  files, then STOP and wait for "next". Never jump ahead.
- Keep replies short.

## Known findings from the official 7.0 templates (decide, don't rediscover)

- `Windows/Linux by Zabbix agent active` already have `Active checks are not available`
  (HIGH, `{$AGENT.TIMEOUT}`=5m) and `Zabbix agent is not available` (AVERAGE, nodata
  `{$AGENT.NODATA_TIMEOUT}`=30m). Adding the draft's "agent + ICMP" trigger duplicates
  alerts on a real outage; trigger dependencies cannot be added to official triggers.
- Official FS triggers: WARNING at `{$VFS.FS.PUSED.MAX.WARN}`=80, AVERAGE at
  `{$VFS.FS.PUSED.MAX.CRIT}`=90. Draft wants Warning 85 / High 95 + timeleft < 14 d.
- Linux official has `Number of installed packages has been changed` (WARNING,
  tag scope=notice), no macro to disable; fires after every patch.
- Windows official service LLD discovers all automatic services (AVERAGE trigger);
  filter macros `{$SERVICE.NAME.MATCHES}` / `{$SERVICE.NAME.NOT_MATCHES}` /
  `{$SERVICE.STARTUPNAME.MATCHES}`.
- Official 7.0 has no time-drift trigger (only `system.localtime` item).
- `Systemd by Zabbix agent 2` uses passive items; MON-SRV agents are active-only.
Ask Asmir how to resolve the first three before building MON-SRV.
