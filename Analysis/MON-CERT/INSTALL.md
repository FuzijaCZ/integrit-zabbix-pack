# MON-CERT: internal certificates, PKI and Apple tokens: installation

Version 1.0 · Zabbix 7.0.31. Draft reference: section 5.6.9.

Scope boundary: public web / domain certificates stay in MON-WEB / MON-DNS, Entra app secrets in MON-M365, the Exchange certificate
and MX STARTTLS in MON-MAIL. MON-CERT covers everything else that expires quietly.

| Template | Linked on | Collected by |
|---|---|---|
| `INT MON-CERT Endpoints` | one probe host per customer site (e.g. `<site> CERT probe`) | site proxy, ExternalScript `int-cert-check.py` |
| `INT MON-CERT Windows store` | Windows servers with own certificates (RDS, IIS, ADFS, NPS, SQL TLS), next to `INT MON-SRV Windows` | agent 2 (active) |
| `INT MON-CERT AD CS` | the AD CS certification authority server | agent 2 (active) |
| `INT MON-CERT Intune Apple` | the customer's MON-M365 tenant host (if Intune manages Apple devices) | external proxy, Script item (Graph) |

## Files

| File | Where |
|---|---|
| `template_int_mon_cert_probe.yaml` | Zabbix import (Endpoints) |
| `template_int_mon_cert_windows.yaml` | Zabbix import (Windows store, AD CS) |
| `template_int_mon_cert_intune.yaml` | Zabbix import (Intune Apple) |
| `externalscripts/int-cert-check.py` | **every site proxy**: `/usr/lib/zabbix/externalscripts/int-cert-check.py` (0755, root) |
| `windows/int_mon_cert.ps1` | `C:\Program Files\Zabbix Agent 2\scripts\int_mon_cert.ps1` |
| `windows/int_mon_cert.conf` | `C:\Program Files\Zabbix Agent 2\zabbix_agent2.d\int_mon_cert.conf` |

## Triggers

| Trigger | Severity | Default |
|---|---|---|
| Certificate expires soon (endpoint, Windows store) | WARNING / AVERAGE / HIGH | < 30 / < 14 / < 3 days (chained, one problem at a time) |
| Certificate expired or invalid chain / host name (endpoint) | HIGH | – |
| Certificate expired (Windows store) | HIGH | – |
| ACME certificate not renewed | WARNING | older than 60 days and issuer is Let's Encrypt / ZeroSSL |
| Endpoint cannot be checked · no data | WARNING | 2 checks in a row · 3 h |
| CRL expires (nextUpdate) | HIGH | < 24 h |
| CRL cannot be downloaded | HIGH | 1 h |
| CA certificate expires | AVERAGE / HIGH | < 180 / < 30 days |
| APNs certificate / VPP token / ADE token expires | AVERAGE / HIGH | < 30 / < 7 days |
| Apple token check fails · no data | AVERAGE | 2 runs · 36 h |

Thresholds of endpoints and CRLs can be set per entry with macro context, e.g. `{$INT.CERT.DAYS.WARN:"RD Gateway"}=45`.
Not in v1.0: failed AD CS requests, CA service state (use MON-SRV critical list: `CertSvc`), RDP certificates with standard RDP security.

## 1. What the customer provides

- List of internal endpoints (Integrit proposes it at onboarding: scan known hosts on 443 / 636 / 3389 / 25 from the site proxy, then the
  customer confirms). For each: DNS name (not IP: the host name is part of the validity check), port, protocol.
- The internal root CA certificate (`.cer`), if they have AD CS or another internal CA.
- MON-SRV agent on the CA server and on servers with own certificates.
- For Apple tokens: consent for two extra Graph permissions on the Integrit Monitoring app (step 5).

## 2. Site proxy (once per proxy)

```
install -m 0755 -o root int-cert-check.py /usr/lib/zabbix/externalscripts/
```
Python 3.7+ standard library only. Internal CA: add its root so chains validate:
```
cp acme-root-ca.cer /usr/local/share/ca-certificates/acme-root-ca.crt   # PEM; DER: openssl x509 -inform DER -in x.cer -out x.crt
update-ca-certificates
```
A site proxy serves one customer, so the customer root never affects other customers.

Test: `sudo -u zabbix /usr/lib/zabbix/externalscripts/int-cert-check.py tls rdg.acme.cz 443 tls` → JSON with `"valid": 1` and `days`.
Modes: `tls` (HTTPS, LDAPS 636, IMAPS ...), `smtp` (STARTTLS on 25/587), `ldap` (StartTLS on 389), `rdp` (3389).
CRL: `... int-cert-check.py crl http://pki.acme.local/CertEnroll/Acme-CA.crl` → `hours_left`.

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

Import the three files one by one with the same boxes.

## 4. Hosts

**Probe host** (one per site): name `<site> CERT probe`, customer and site groups + `Services/MON-CERT`, tags per Part 3
(`service=MON-CERT`), monitored by the **site proxy**, no interface needed. Link `INT MON-CERT Endpoints`. Macros (entries separated by
`;`, fields by `|`):
```
{$INT.CERT.ENDPOINTS}  RD Gateway|rdg.acme.cz|443|tls;DC01 LDAPS|dc01.acme.local|636|tls;Firewall admin|fw.acme.local|4443|tls;RDS01 RDP|rds01.acme.local|3389|rdp;Relay|smtp.acme.local|25|smtp
{$INT.CERT.CRL.URLS}   Acme Root CA|http://pki.acme.local/CertEnroll/Acme-Root-CA.crl;Acme Issuing CA|http://pki.acme.local/CertEnroll/Acme-Issuing-CA.crl
```
CDP URLs: open any issued certificate → Details → CRL Distribution Points (HTTP entries only; LDAP CDPs are not checked).
Include the root CA CRL: offline roots publish rarely and their CRL expiry is the classic surprise.
Self-signed devices (printers, NAS, switches): `{$INT.CERT.VERIFY:"<label>"}=0` (expiry is still alerted).

**Windows servers:** copy `int_mon_cert.ps1` and `int_mon_cert.conf`, `Restart-Service "Zabbix Agent 2"`, link `INT MON-CERT Windows store`.
Unwanted certificates: `{$INT.CERT.STORE.SUBJECT.NOT_MATCHES}` (regex on the subject). Include self-signed: `{$INT.CERT.STORE.SELF.MATCHES}=^[01]$`.

**CA server:** the same files, link `INT MON-CERT AD CS` (and `INT MON-CERT Windows store`). Add `CertSvc` to the MON-SRV critical
service list and its `{$SERVICE.NAME.NOT_MATCHES}` (MON-SRV INSTALL step 4).

## 5. Intune Apple tokens

1. Integrit Monitoring (read) app → API permissions → Microsoft Graph, Application: `DeviceManagementServiceConfig.Read.All`,
   `DeviceManagementApps.Read.All`. New permissions need **admin consent again in every customer tenant**
   (`https://login.microsoftonline.com/<tenant>/adminconsent?client_id=<appid>`).
2. Link `INT MON-CERT Intune Apple` on the customer's MON-M365 tenant host. The `{$MS365.*}` macros are already set on that host.
3. Customers without Apple devices: do not link (nothing alerts anyway, values stay empty).

## 6. Verify

1. Probe host → Discovery: both rules Status Normal. Latest data: `<label>: Certificate days left` matches the browser certificate view;
   `<label>: Certificate valid` = yes (no → see `<label>: Verify error`: "unable to get local issuer certificate" = root CA missing in step 2).
2. `CRL <label>: Hours to nextUpdate` is positive and roughly matches `certutil -dump <file>.crl` NextUpdate.
3. Windows: `zabbix_agent2.exe -c "C:\Program Files\Zabbix Agent 2\zabbix_agent2.conf" -t int.cert.store` → JSON list; the host gets one
   `Certificate <subject>: Days left` item per certificate. CA: `-t int.cert.ca` → `{"ca":"<CA name>","days":...}`.
4. Intune: Latest data → `Apple tokens raw` → Execute now; `Apple: APNs certificate days left` matches Intune → Tenant administration →
   Connectors and tokens → Apple MDM Push certificate.
5. Threshold test: set `{$INT.CERT.DAYS.WARN:"<label>"}=9999` on the probe host → WARNING within 1 h; remove the macro.

Not tested in the build environment: the PowerShell script, the RDP / LDAP StartTLS modes and the Graph calls against a real tenant
(TLS and CRL modes tested locally, Graph logic tested with a mock). Test on the first customer before rollout.
