# MON-ENV: server room environment (generic SNMP sensors): installation

Version 1.0 · Zabbix 7.0.31. Draft reference: section 5.6.2.

`INT MON-ENV SNMP sensors` works with **any SNMP sensor unit** (HW group STE2 / Poseidon2, Comet Web Sensor, Papouch, AKCP, ...).
No vendor MIB is imported: each sensor is one entry in a host macro with its numeric OID. One host per sensor unit, polled by the site proxy.

**Not a fire alarm or intrusion system (EPS/PZTS).** Smoke is informative only; this must be in the customer text and contract.

## Files

| File | Where |
|---|---|
| `template_int_mon_env_snmp.yaml` | Zabbix import |

## Triggers

Defaults follow ASHRAE A1 (inlet 18–27 °C). Every threshold can be set per sensor with macro context, e.g. `{$INT.ENV.TEMP.WARN:"Room"}=30`.

| Trigger | Severity | Default |
|---|---|---|
| High temperature | AVERAGE | > 27 °C for 10 min |
| Critical temperature | HIGH | > 32 °C for 5 min |
| Extreme temperature | DISASTER | > 35 °C (2 values) |
| Temperature rising fast (cooling failure) | HIGH | + 3 °C within 15 min (last − min 15 min) |
| Humidity out of range | WARNING | < 20 or > 70 %RH for 30 min |
| Water detected | DISASTER | any |
| Smoke detected | DISASTER | any (informative) |
| Door open | INFO · WARNING outside Mon–Fri 07:00–18:00 | open > 15 min |
| Mains power lost (dry contact) | HIGH | 2 values |
| Sensor sends no data | AVERAGE | `nodata` 15 min, depends on the unit trigger |
| Sensor unit not responding to SNMP | AVERAGE | 5 min |

Dependency chain: AVERAGE → HIGH → DISASTER (one problem at a time per sensor). "Rising fast" depends on "Critical".
Not in v1.0: wireless sensor battery (vendor specific: add it as a temperature-style entry with its own threshold macro on request), Aranet Cloud.

## 1. What the customer provides

- Mounting places: rack inlet at half height, near the HVAC outlet, flood sensor under the HVAC unit / raised floor.
- LAN / PoE port and a fixed IP for the unit (DHCP reservation).
- The HVAC service contact (alerts are useless if nobody repairs the cooling at night). Put it in the host description.

## 2. Sensor unit

1. Set a static IP, enable **SNMP v2c** (or v3) read-only, change the default community, allow only the site proxy IP if the unit can.
2. Find the OIDs from the site proxy: `snmpwalk -v2c -c <community> -On <unit-ip> .1.3.6.1.4.1` and match the values to the sensors
   shown on the unit's web page. Note per sensor: numeric OID, and whether the value is in tenths (multiplier `0.1`) or whole units (`1`).
   For contacts (flood, door, smoke, mains) note which value means **alarm** (open the door / wet the sensor and walk again).

Typical OIDs (verify on the device, firmware can differ):

| Unit | Value OID | Multiplier |
|---|---|---|
| HW group STE2 / Poseidon2 | `1.3.6.1.4.1.21796.4.9.3.1.5.<sensor index>` (sensValue) | `0.1` |
| Comet Web Sensor P85xx | `1.3.6.1.4.1.22626.1.5.2.<channel>.3.0` (integer ×10) | `0.1` |

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

Host `<site> ENV <unit>`, customer and site groups + `Services/MON-ENV`, tags per Part 3 (`service=MON-ENV`), monitored by the
**site proxy**, **SNMP interface** with the unit IP and `{$SNMP_COMMUNITY}` (or v3 credentials). Link `INT MON-ENV SNMP sensors`.

Sensor macros: entries separated by `;`, fields by `|` (a literal `|` inside a field is written `\|`). Empty macro = no sensors of that type.

Examples (type exactly this into the macro value):
```
{$INT.ENV.TEMP.SENSORS}   Rack inlet|1.3.6.1.4.1.21796.4.9.3.1.5.1|0.1;Room|1.3.6.1.4.1.21796.4.9.3.1.5.2|0.1
{$INT.ENV.HUM.SENSORS}    Room|1.3.6.1.4.1.21796.4.9.3.1.5.3|0.1
{$INT.ENV.FLOOD.SENSORS}  Under HVAC|<OID from step 2>|1
{$INT.ENV.DOOR.SENSORS}   Rack door|<OID>|1
{$INT.ENV.SMOKE.SENSORS}  Room|<OID>|1
{$INT.ENV.POWER.SENSORS}  Mains|<OID>|0            (value when mains is LOST)
```
The last field of a contact is a regex of alarm values; two values are written `1\|2` (escaped, because `|` separates fields).

Per-sensor thresholds: add `{$INT.ENV.TEMP.WARN:"Room"}` etc. with the sensor label as context. Working hours: `{$INT.ENV.WORK.START}` /
`{$INT.ENV.WORK.END}` (hhmmss).

Dependencies: add a host-level dependency of "Sensor unit ... not responding" on the site gateway trigger (MON-NET INSTALL step 4).
A temperature rise together with MON-UPS "on battery" is expected (HVAC is rarely on UPS) but still alerted.

## 5. Verify

1. Data collection → Hosts → the host → Discovery: the rules for the filled macros show **Status: Normal**; Execute now if needed.
   A wrong entry (missing field) makes the rule Not supported with the entry in the error text.
2. Latest data: `Temperature <label>` matches the unit's web page (if it is 10× too high, set the multiplier to `0.1`).
3. Contact test: open the rack door → `Door <label>` = ALARM; after 15 min the INFO problem (WARNING outside working hours). Wet the flood
   sensor with a damp cloth → DISASTER "Water detected" within 1 min. Tell the on-call engineer before testing.
4. Unplug the unit's LAN → after 5 min AVERAGE "Sensor unit ... not responding"; the per-sensor "no data" problems stay suppressed.

## 6. Add-on: rack PDUs (`template_int_mon_env_pdu.yaml`)

| Template | For | Triggers |
|---|---|---|
| `INT MON-ENV APC Rack PDU` | APC / Schneider metered / switched rack PDUs (AP7xxx, AP8xxx, PowerNet-MIB rPDU2) | phase / bank **overload** HIGH, **near overload** AVERAGE (thresholds configured on the PDU), PDU not responding AVERAGE |
| `INT MON-ENV PDU generic` | any SNMP PDU (Eaton, Raritan, Vertiv, ...) | current per label > `{$INT.PDU.CURRENT.WARN}` (8 A) AVERAGE / > `{$INT.PDU.CURRENT.CRIT}` (14 A) HIGH for 5 min |

Items for the report: current per phase / bank, voltage, power (kW), energy counter (kWh, 400 days history: monthly consumption).
A/B power rule: on redundant feeds each PDU must stay below half of its circuit rating, so that one side can carry everything when
the other fails. Set the near-overload threshold on the APC PDU (web UI → Configuration → Device / Phase / Bank) accordingly.

Import: same boxes as step 3 (the file uses the same template group `Templates/Integrit/MON-ENV`).

Host: one per PDU, SNMP interface (v3 where the card supports it), group `Services/MON-ENV`, link the matching template.
Generic PDU macro example (find the OIDs with `snmpwalk` as in step 2):
```
{$INT.PDU.CURRENTS}  Phase L1|<current OID of phase 1>|0.1;Phase L2|<OID>|0.1;Phase L3|<OID>|0.1
{$INT.PDU.CURRENT.CRIT:"Phase L1"}  28     (32 A circuit)
```
An APC PDU with an environment probe (AP9335T): link both `INT MON-ENV APC Rack PDU` and `INT MON-ENV SNMP sensors` on the same host
and list the probe OIDs in the sensor macros.

Verify: Latest data → `Phase 1: current` matches the PDU display; `PDU: energy` increases. APC OID columns (rPDU2 phase table
.26.6.3.1, bank table .26.8.3.1, device table .26.4.3.1) follow PowerNet-MIB; confirm with `snmpwalk` on the first PDU.
