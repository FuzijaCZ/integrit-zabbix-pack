# MON-M365: Microsoft 365 and licences: installation

Version 1.0 · Zabbix 7.0.31 · official templates `release/7.0` (commit 362508f). Draft reference: sections 4.14 and 5.3.

One template, `INT MON-M365 Tenant`, on one host per customer tenant (`<CUST>-M365`, monitored by the **external proxy group**, no interface).
It links the official `Microsoft 365 reports by HTTP` (service health and usage reports) and adds licences and tenant hygiene from Microsoft Graph.

## Files

| File | Template |
|---|---|
| `template_int_mon_m365.yaml` | `INT MON-M365 Tenant` |

## Triggers

| Trigger | Severity | Default |
|---|---|---|
| Service degraded / interrupted (official) | WARNING / AVERAGE | all services; filter with `{$MS365.SERVICE.NAME.MATCHES}` to the services the customer uses |
| Licence SKU in Warning / Suspended / LockedOut | HIGH | subscription expired (grace) or suspended |
| Free licences below threshold | WARNING | `{$INT.M365.SKU.MIN.FREE}`=0 (= more assigned than bought); per SKU e.g. `{$INT.M365.SKU.MIN.FREE:"SPE_E3"}=2` |
| Subscription ends in < 30 / < 7 days | AVERAGE / HIGH | only SKUs with `{$INT.M365.SUB.EXPIRY.CHECK:"<SKU>"}=1` (no auto-renewal) |
| Directory sync older than 3 h | HIGH | hybrid tenants only (Entra Connect / Cloud Sync) |
| App secret / certificate expires | WARNING | < 30 days, nearest credential of all app registrations |
| Global administrators outside 2–5 | WARNING | `{$INT.M365.GA.MIN}` / `{$INT.M365.GA.MAX}` |
| Graph errors (token / consent / permission) | AVERAGE | required checks only |
| Paid licences on disabled / inactive users | INFO (report only) | inactive = no sign-in for 30 days (needs Entra ID P1) |
| Official API error triggers | AVERAGE | per report group |

Report-only values (no trigger): users without MFA, Secure Score %, usage reports from the official template.
Checks that need Entra ID P1 (MFA report, sign-in activity) or Secure Score permission do not alert when unavailable. Their errors
go to item `Tenant: Optional check errors`.

Why subscription expiry is opt-in: Graph does not say whether a subscription auto-renews. `nextLifecycleDateTime` is the renewal date
for auto-renewing (e.g. monthly NCE) subscriptions too, so an always-on trigger would alert before every renewal.

## 1. One-time Integrit setup: multi-tenant app "Integrit Monitoring (read)"

Draft 5.3 recommends one read-only multi-tenant app for all Graph-based services (MON-M365, later MON-IDSEC, MON-MDM, MON-MAIL).
Define all permissions up front, because adding one later needs new consent in every tenant.

1. Integrit tenant → Entra admin center → App registrations → New: name `Integrit Monitoring (read)`,
   **Accounts in any organizational directory (multitenant)**, no redirect URI.
2. API permissions → Microsoft Graph → **Application** permissions:
   `Reports.Read.All`, `ServiceHealth.Read.All`, `Organization.Read.All`, `Directory.Read.All`, `Application.Read.All`,
   `AuditLog.Read.All`, `SecurityEvents.Read.All`.
3. Certificates & secrets → New client secret (24 months). Track the expiry (MON-CERT; this template's own app-credential check covers the
   **customer** tenant only).

## 2. Per customer

1. The customer's Global Administrator opens (once):
   `https://login.microsoftonline.com/<customer-tenant-domain>/adminconsent?client_id=<app client id>`
   and accepts. The customer can revoke it any time (Enterprise applications → Integrit Monitoring (read) → Delete).
2. Create host `<CUST>-M365`: groups `Customers/<CUST>` + `Services/MON-M365`, monitored by the external proxy group, no interface,
   template `INT MON-M365 Tenant`, tags `customer`, `managed`, `tier`, `contract` (site tag: `cloud`).
3. Host macros:

| Macro | Value |
|---|---|
| `{$MS365.TENANT.ID}` | customer tenant ID or primary domain, e.g. `acme.cz` |
| `{$MS365.APP.ID}` | client ID of `Integrit Monitoring (read)` |
| `{$MS365.PASSWORD}` | client secret (type Secret text) |
| `{$MS365.SERVICE.NAME.MATCHES}` | e.g. `^(Exchange Online|Microsoft Teams|SharePoint Online|OneDrive for Business|Microsoft Entra)$` |
| `{$INT.M365.SKU.MIN.FREE:"<SKU>"}` | spare licences the customer wants to keep |
| `{$INT.M365.SUB.EXPIRY.CHECK:"<SKU>"}` | `1` for subscriptions without auto-renewal |

SKU names are the Graph `skuPartNumber` (e.g. `O365_BUSINESS_PREMIUM` = Microsoft 365 Business Premium, `SPE_E3` = Microsoft 365 E3,
`EXCHANGESTANDARD` = Exchange Online Plan 1). They appear in item names after the first run.

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

## 4. Verify

1. Host → Items → `Tenant: Get data` → **Execute now**; after about 1 min Latest data shows `Tenant: Graph errors` empty and
   `Tenant: Global administrators` > 0.
2. One `Licence <SKU>: Purchased / Assigned / Free` set per paid SKU, matching Microsoft 365 admin center → Billing → Licenses.
3. Hybrid tenant: `Tenant: Directory sync age` below 1 h (Entra Connect runs every 30 min).
4. Official items: `Services: Get services` without errors; one `... health` item per service.
5. Consent test: a wrong `{$MS365.PASSWORD}` gives AVERAGE `INT: M365 Graph API errors` after the next run (Execute now); restore it.
