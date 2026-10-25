# MON-CLOUD: public cloud resources (Azure first, AWS on request): installation

Version 1.0 · Zabbix 7.0.31. Draft reference: section 5.6.14.

| Template | Host | Official template inside |
|---|---|---|
| `INT MON-CLOUD Azure subscription` | one per customer subscription | `Azure Cost Management by HTTP` |
| `INT MON-CLOUD Azure VM` | one per important VM | `Azure Virtual Machine by HTTP` |
| `INT MON-CLOUD Azure SQL database` | one per production Azure SQL DB (vCore) | `Azure Microsoft SQL Database by HTTP` |
| `INT MON-CLOUD Azure backup vault` | one per Recovery Services vault | `Azure Backup Jobs by HTTP` |
| `INT MON-CLOUD AWS account` | one per AWS account (on request) | `AWS Cost Explorer by HTTP` |

All hosts are monitored by the **external proxy**, no interface. The official `Azure by HTTP` / `AWS by HTTP` discovery templates
are **not** used: they create hosts with fixed names (`Azure VM {#NAME}`) in shared global groups (`Virtual machines`, `Databases`).
Two customers with a VM named `web01` would collide, and discovered hosts carry no customer group or tags. Per-resource hosts are
created by Integrit (onboarding tool or by hand) in the customer's groups: tenants stay separated and billing counts predictable.

## Files

| File | Where |
|---|---|
| `template_int_mon_cloud.yaml` | Zabbix import |
| `lighthouse/integrit-lighthouse.json` | sent to the customer / deployed in their subscription (step 2) |

## Triggers

| Trigger | Severity | Default | From |
|---|---|---|---|
| Azure VM stopped / deallocated unexpectedly | HIGH | 2 checks (10 min), VMs without tag `zabbix-ignore-power` | INT subscription |
| Resources unavailable / degraded (Resource Health) | AVERAGE | 2 checks | INT subscription |
| Azure service issue affects the subscription | AVERAGE | parent of the two above | INT subscription |
| Cost over budget · forecast over budget | AVERAGE · WARNING | `{$INT.CLOUD.BUDGET}` (0 = off) | INT subscription, daily 07:00 |
| Daily cost anomaly | WARNING | yesterday > 2 × 7-day average and > 10 | INT subscription |
| API access fails · no data · cost data unavailable | AVERAGE · AVERAGE · WARNING | Integrit internal | INT subscription |
| VM unavailable / degraded / high CPU | HIGH / AVERAGE / HIGH | CPU > 95 % 5 min | official VM |
| SQL storage low / critically low | WARNING / AVERAGE | > 85 % / > 95 % | official SQL DB |
| Backup job failed / restore / deletion job | HIGH / AVERAGE / WARNING | – | official backup |

Deviation: the draft wants SQL storage 85 % AVERAGE / 95 % HIGH; the official template's severities are fixed (WARNING / AVERAGE),
only the thresholds are set to 85 / 95.
Not in v1.0: Azure Advisor recommendations (report), AWS cost budget triggers (official cost items only), GCP.

## 1. What the customer provides

- Acceptance of Azure Lighthouse delegation (or a service principal per subscription if they refuse Lighthouse).
- Subscriptions in scope; resource groups out of scope (dev / test); monthly budget per subscription.
- Which VMs / databases / vaults are important (they get their own hosts, billed per resource).
- Tag `zabbix-ignore-power` on VMs that are switched off on purpose.
- AWS: a cross-account read-only IAM role trusting the Integrit account (`ReadOnlyAccess` or `CloudWatchReadOnlyAccess` +
  `ce:GetCostAndUsage`), its ARN.

## 2. Azure access (Lighthouse, recommended)

Once in the Integrit tenant: App registration `Integrit Zabbix Azure` (single tenant) with a client secret (24 months, calendar
reminder). Note its **Enterprise application object ID**. Global macros: `{$AZURE.APP.ID}`, `{$AZURE.PASSWORD}` (Secret text),
`{$AZURE.TENANT.ID}` = **Integrit** tenant ID.

Per customer subscription: the customer (Owner of the subscription) deploys `lighthouse/integrit-lighthouse.json`:
```
az deployment sub create --location westeurope --template-file integrit-lighthouse.json \
   --parameters managedByTenantId=<Integrit tenant ID> principalId=<Enterprise app object ID>
```
It grants **Reader**, **Monitoring Reader** and **Cost Management Reader**, read-only, visible and removable by the customer in
Azure → Service providers. Without Lighthouse: an app registration in the customer tenant with the same three roles on the
subscription; then set `{$AZURE.TENANT.ID}`, `{$AZURE.APP.ID}`, `{$AZURE.PASSWORD}` on the customer's hosts instead.

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

All: customer group + `Services/MON-CLOUD`, tags per Part 3, external proxy, no interface.

| Host | Template | Host macros |
|---|---|---|
| `<CUST>-AZ-<subscription name>` | `INT MON-CLOUD Azure subscription` | `{$AZURE.SUBSCRIPTION.ID}`, `{$INT.CLOUD.BUDGET}` (e.g. `1200`), `{$INT.CLOUD.CURRENCY}`, optional `{$AZURE.RESOURCE.GROUP.NOT.MATCHES}` |
| `<CUST>-AZ-VM-<name>` | `INT MON-CLOUD Azure VM` | `{$AZURE.SUBSCRIPTION.ID}`, `{$AZURE.RESOURCE.ID}` = VM resource ID (VM → Properties → Resource ID) |
| `<CUST>-AZ-SQL-<name>` | `INT MON-CLOUD Azure SQL database` | same two macros, resource ID of the database |
| `<CUST>-AZ-RSV-<name>` | `INT MON-CLOUD Azure backup vault` | same two macros, resource ID of the vault |
| `<CUST>-AWS-<account>` | `INT MON-CLOUD AWS account` | `{$AWS.ASSUME.ROLE.ARN}`, `{$AWS.ACCESS.KEY.ID}` / `{$AWS.SECRET.ACCESS.KEY}` of the Integrit IAM user that assumes the role |

The OS inside cloud VMs is monitored by MON-SRV (agent through the site / cloud proxy).
Dependency: VM / SQL hosts' "unavailable" triggers can get a host-level dependency on the subscription's "Azure service issue"
trigger (MON-NET INSTALL step 4 caveat applies).

## 5. Verify

1. Subscription host → Latest data → `Azure health raw` → Execute now: `Azure: API errors` empty, `Azure: VMs running` = running VMs.
2. Next day after 07:00: `Cost: month to date` matches Azure → Cost Management → Cost analysis (actual, this month) within a few %.
3. VM host: the availability state item shows Available; SQL host: storage percent filled.
4. Lighthouse check at the customer: Azure portal → Service providers → "Integrit monitoring (read-only)" with three roles.

Tested with mocked Azure responses only (subscription script); the official templates follow Zabbix docs.
