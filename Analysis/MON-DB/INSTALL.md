# MON-DB: databases: installation

Version 1.0 · Zabbix 7.0.31 · official templates `release/7.0` (commit 362508f). Draft reference: section 5.6.6.

All database checks run in the **Zabbix agent 2 on the database server** (already installed by MON-SRV), so there is no new network path.
Link the MON-DB template on the existing MON-SRV host.

## Which template

| Engine | Template | Note |
|---|---|---|
| Microsoft SQL Server 2017–2025 (incl. Express) | `INT MON-DB MSSQL` | Integrit template, **active** items on the agent 2 MSSQL plugin |
| MySQL / MariaDB | `INT MON-DB MySQL` | links official `MySQL by Zabbix agent 2 active` |
| PostgreSQL | `INT MON-DB PostgreSQL` | links official `PostgreSQL by Zabbix agent 2 active` (on request) |

**Why MSSQL is not a wrapper:** the official `MSSQL by Zabbix agent 2` has passive items only, and Integrit agents are active-only (draft 3.1.7).
`INT MON-DB MSSQL` uses the same plugin keys as active items, limited to the checks draft 5.6.6 alerts on.

## Files

| File | Templates |
|---|---|
| `template_int_mon_db_mssql.yaml` | `INT MON-DB MSSQL` |
| `template_int_mon_db_open.yaml` | `INT MON-DB MySQL`, `INT MON-DB PostgreSQL` |

## Triggers (MSSQL)

| Trigger | Severity | Default |
|---|---|---|
| SQL Server instance down (plugin cannot log in) | HIGH / DISASTER with `{$INT.TIER.CRITICAL}=1` | 3 min |
| Database not ONLINE | HIGH | 3 checks |
| Last full backup too old (also "never backed up") | HIGH | `{$INT.MSSQL.BACKUP.FULL.MAXAGE}`=26h, context per DB |
| FULL recovery model, last log backup too old | AVERAGE | `{$INT.MSSQL.BACKUP.LOG.MAXAGE}`=2h |
| Express database near the size limit | AVERAGE / HIGH | 80 % / 95 % of `{$INT.MSSQL.EXPRESS.LIMIT}`=10G (SQL 2025 Express: set `50G`) |
| Transaction log used | WARNING | > 80 % for 30 min |
| SQL Agent job failed | AVERAGE | enabled jobs, last run failed |
| Sessions blocked | WARNING | blocked continuously for 2 min |
| Deadlocks | WARNING | every minute for 15 min |

The backup checks read msdb, so they work for any backup product (Veeam, native, maintenance plan) and catch databases missing from the backup job.
System databases (`master`, `model`, `msdb`, `tempdb`) are excluded by `{$INT.MSSQL.DBNAME.NOT_MATCHES}`. Add `master` and `msdb` back if the
customer wants them checked too.

Not in v1.0 for MSSQL (draft): Always On AG / mirroring (rare in SMB), "file cannot autogrow" (disk space is covered by MON-SRV),
failed-login bursts (planned in MON-SECEVT), page life expectancy / buffer trends.

MySQL / PostgreSQL: official triggers (service down HIGH, connections, replication, slow queries). Their backups are checked through MON-BKP or MON-CUSTOM.

## 1. What the customer provides

- A monitoring login (below) or permission for Integrit to create it. Some ERP vendors forbid third-party logins on their instance: check the contract.
- The list of databases in scope and the backup expectation per database (full daily? log hourly? monthly archive?).
- Contact of the application owner / ERP vendor (job failures often go to them).

## 2. Agent and login

**MSSQL plugin** (Windows): install `zabbix_agent2_plugins-7.0.x-windows-amd64.msi` (version ≥ 7.0.10, same 7.0.x as the agent). It registers the MSSQL plugin in
`zabbix_agent2.d\plugins.d\mssql.conf`. Restart the agent.
Monitoring login (SQL 2022+; for 2017/2019 use `GRANT VIEW SERVER STATE` instead of the first GRANT):

```sql
CREATE LOGIN zabbix WITH PASSWORD = '<strong password>', CHECK_POLICY = ON;
GRANT VIEW SERVER PERFORMANCE STATE TO zabbix;
GRANT VIEW ANY DEFINITION TO zabbix;
USE msdb;
CREATE USER zabbix FOR LOGIN zabbix;
GRANT EXECUTE ON msdb.dbo.agent_datetime TO zabbix;
GRANT SELECT ON msdb.dbo.sysjobactivity TO zabbix;
GRANT SELECT ON msdb.dbo.sysjobservers TO zabbix;
GRANT SELECT ON msdb.dbo.sysjobs TO zabbix;
GRANT SELECT ON msdb.dbo.backupset TO zabbix;
```

SQL authentication must be enabled (Server properties → Security → SQL Server and Windows Authentication mode). Express named instances:
enable TCP/IP in SQL Server Configuration Manager.

**MySQL / MariaDB:** `CREATE USER 'zbx_monitor'@'localhost' IDENTIFIED BY '<pw>'; GRANT REPLICATION CLIENT, PROCESS, SHOW DATABASES, SHOW VIEW ON *.* TO 'zbx_monitor'@'localhost';`
**PostgreSQL:** `CREATE USER zbx_monitor WITH PASSWORD '<pw>' INHERIT; GRANT pg_monitor TO zbx_monitor;` plus a `pg_hba.conf` line for local md5/scram.

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

On the MON-SRV host of the DB server: add group `Services/MON-DB`, link the template, set macros:

| Template | Macros |
|---|---|
| `INT MON-DB MSSQL` | `{$MSSQL.URI}` (`sqlserver://localhost:1433` or `sqlserver://localhost/SQLEXPRESS`), `{$MSSQL.USER}`, `{$MSSQL.PASSWORD}` (secret), `{$INT.TIER.CRITICAL}`, per-DB backup ages e.g. `{$INT.MSSQL.BACKUP.FULL.MAXAGE:"Archiv"}=32d` |
| `INT MON-DB MySQL` | `{$MYSQL.DSN}`, `{$MYSQL.USER}`, `{$MYSQL.PASSWORD}` |
| `INT MON-DB PostgreSQL` | `{$PG.CONNSTRING.AGENT2}`, `{$PG.USER}`, `{$PG.PASSWORD}` |

## 5. Verify

1. On the server: `zabbix_agent2.exe -t "mssql.ping[sqlserver://localhost:1433,zabbix,<pw>]"` → `1`. Then `MSSQL: Ping` = Up in Latest data.
2. Within 1 h (database discovery; or *Execute now* on `MSSQL: Get databases`): one item set per database. `Last full backup age` matches the
   last backup date in SSMS (database → Properties → General → Last Database Backup).
3. `MSSQL: Express edition` = Yes on Express instances, and `Data files size` is shown for each database.
4. Test: set `{$INT.MSSQL.BACKUP.FULL.MAXAGE:"<db>"}=1m` → HIGH within 10 min; remove the macro.
