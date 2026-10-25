# MON-IDSEC: Entra ID identity security: installation

Version 1.0 · Zabbix 7.0.31. Draft reference: section 5.6.8.

`INT MON-IDSEC Entra ID` is linked on the customer's **MON-M365 tenant host** (same external proxy, same `{$MS365.*}` credentials of the
Integrit Monitoring read app). It adds security events on top of the MON-M365 hygiene checks. Sold as an upgrade tier of MON-M365.

**Not a SOC:** Integrit alerts and reports, it does not investigate or respond unless agreed separately. Sign-in data is personal
data: the DPA with the customer must cover it.

## Files

| File | Where |
|---|---|
| `template_int_mon_idsec.yaml` | Zabbix import |

## Triggers

Event checks look at a fixed 5-minute window, 15 minutes in the past (Entra log latency), every 5 minutes, so each event is seen
exactly once. The problem name carries the details (who, what, from where). "manual" = stays open until closed after review.

| Trigger | Severity | Licence | Close |
|---|---|---|---|
| Break-glass account signed in | DISASTER | P1 | manual |
| Users at high risk (snapshot) | HIGH | P2 | auto |
| High risk detection | HIGH | P2 | manual |
| Highly privileged role assigned (Global Admin, Privileged Role Admin, Exchange Admin, ...) | HIGH | any | manual |
| Other admin role assigned | AVERAGE | any | manual |
| Conditional Access policy added / changed / deleted | AVERAGE | P1 | manual |
| Security defaults switched off | AVERAGE | any | manual |
| Consent to an app with mail / file / directory permissions | AVERAGE | any | manual |
| New credentials on an application / service principal | WARNING | any | manual |
| Successful sign-in from outside the country allow-list | AVERAGE | P1 | manual |
| Successful legacy authentication sign-in | WARNING | P1 | manual |
| Inbox rule forwards mail outside the organisation (checked every 12 h) | HIGH | any | auto |
| Checks fail / no data | AVERAGE | – | auto |

Defender XDR / Defender for Office alerts are not duplicated here (MON-EPS Defender variant).

## 1. What the customer provides

- Licence overview: Entra ID P1 (Business Premium, E3) and / or P2 (E5, add-on) → macros `{$INT.IDSEC.P1}` / `{$INT.IDSEC.P2}`.
- Break-glass account UPNs (if they have none: recommend two cloud-only accounts excluded from CA, long passwords in the safe).
- Allowed sign-in countries and frequent travellers.
- Agreed external forwarding (e.g. to the accountant's domain).
- On-call expectation for DISASTER (break-glass sign-in at 2 a.m. needs a person).
- Admin consent for the extra permissions (step 2).

## 2. Permissions of the Integrit Monitoring (read) app

Add Microsoft Graph **application** permissions (once, in the Integrit tenant), then re-consent in every customer tenant
(`https://login.microsoftonline.com/<tenant>/adminconsent?client_id=<appid>`):

| Permission | Used for |
|---|---|
| `AuditLog.Read.All` | directory audits, sign-ins |
| `Policy.Read.All` | security defaults |
| `IdentityRiskyUser.Read.All`, `IdentityRiskEvent.Read.All` | risk (P2) |
| `MailboxSettings.Read` | inbox forwarding rules |
| `User.Read.All`, `Domain.Read.All` | users and verified domains (usually already granted for MON-M365) |

Define the full permission set of the read app for all Graph services at once (draft 5.3 point 1), so customers consent only once.

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

On the MON-M365 tenant host: link `INT MON-IDSEC Entra ID`, add group `Services/MON-IDSEC`. Host macros:

| Macro | Example |
|---|---|
| `{$INT.IDSEC.P1}` / `{$INT.IDSEC.P2}` | `1` / `0` |
| `{$INT.IDSEC.BREAKGLASS}` | `bg01@acme.onmicrosoft.com,bg02@acme.onmicrosoft.com` |
| `{$INT.IDSEC.COUNTRIES}` | `CZ,SK,AT,DE` |
| `{$INT.IDSEC.COUNTRY.IGNORE}` | `^(ceo|sales\.export)@acme\.cz$` |
| `{$INT.IDSEC.FWD.ALLOW}` | `ucetni-firma.cz` |

## 5. Verify

1. Latest data → `Identity security raw` → Execute now: `Graph: errors` empty. `Graph: optional check errors` lists only checks the
   tenant has no licence for (then set P1 / P2 to 0 to silence them).
2. Role test (with approval): assign *Helpdesk Administrator* to a test user → within ~25 min AVERAGE "Admin role assigned: Helpdesk
   Administrator -> test@... by admin@...". Remove the role, close the problem.
3. Forwarding test: create an inbox rule in a test mailbox forwarding to a Gmail address → after the next 12-hourly run (or Execute now
   on `Mail forwarding rules raw`) HIGH "Inbox rule forwards mail outside the organisation". Delete the rule.

Not tested against a real tenant (logic tested with mocked Graph responses). Audit activity names are Microsoft's English strings
and occasionally change: check `Graph: errors` and the role test on the first customer.
