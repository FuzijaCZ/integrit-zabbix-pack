# MON-WEB-FUNC: functional web and form checks: installation

Version 1.0 · Zabbix 7.0.31. Draft reference: section 4.12.

`INT MON-WEB-FUNC Scenario` runs one user journey per Zabbix host (e.g. `ACME-WEB-CONTACTFORM`) in a real Chrome browser, using the
Zabbix 7.0 **Browser item** on the external proxy. Optionally it checks that the confirmation / lead e-mail arrives in an Integrit test mailbox.

## Files

| File | Template |
|---|---|
| `template_int_mon_webfunc.yaml` | `INT MON-WEB-FUNC Scenario` |

## Triggers

| Trigger | Severity | Default |
|---|---|---|
| Scenario failed twice in a row | HIGH | interval `{$INT.WEBFUNC.INTERVAL}`=30m → about 1 h to alert |
| Confirmation mail not received | HIGH | only with `{$INT.WEBFUNC.MAIL.CHECK}=1`; window 45 min |
| Scenario slower than limit | WARNING | > `{$INT.WEBFUNC.DURATION.MAX}`=30 s twice |
| Confirmation mail check fails (Graph error) | AVERAGE | only with mail check on |

On failure, the screenshot of the failed step is in Latest data → `Scenario: Screenshot` (kept 7 days).
Draft "from both locations": Zabbix 7.0 runs a Browser item on one proxy, so the second location is replaced by "failed twice in a row".

## Writing the steps (`{$INT.WEBFUNC.STEPS}`, JSON, max 2048 characters)

| Action | Fields | Example |
|---|---|---|
| `open` | `url` | `{"action":"open","url":"https://www.acme.cz/kontakt"}` |
| `fill` | `selector` or `xpath`, `value` (`{TS}` = Unix time) | `{"action":"fill","selector":"#email","value":"webtest+{TS}@integrit.cz"}` |
| `click` | `selector` or `xpath` | `{"action":"click","selector":"button[type=submit]"}` |
| `expect` | `selector` or `xpath`, optional `text` | `{"action":"expect","selector":".wpcf7-response-output","text":"Děkujeme"}` |
| `expect_url` | `contains` | `{"action":"expect_url","contains":"/dekujeme"}` |

Optional `name` per step appears in "Failed step". Example contact form (WordPress Contact Form 7):

```json
[{"name":"open form","action":"open","url":"https://www.acme.cz/kontakt"},
 {"action":"fill","selector":"input[name=your-name]","value":"INT-TEST Integrit monitoring"},
 {"action":"fill","selector":"input[name=your-email]","value":"webtest+{TS}@integrit.cz"},
 {"action":"fill","selector":"textarea[name=your-message]","value":"INT-TEST automated check, please ignore"},
 {"name":"submit","action":"click","selector":"input[type=submit]"},
 {"name":"thank you","action":"expect","selector":".wpcf7-response-output","text":"Děkujeme"}]
```

Find selectors in Chrome: right-click the field → Inspect → right-click the element → Copy → Copy selector.
E-shop checkouts must stop **before payment** (last step = expect on the payment page).

## 1. What the customer provides (critical, draft 4.12 point 4)

- The agreed journey and the expected result (text or URL after submit).
- **How test submissions are marked** so they do not pollute CRM / leads: the name/subject `INT-TEST` and address `webtest+…@integrit.cz`,
  plus a customer-side rule that drops or tags them.
- **CAPTCHA exception** for the Integrit external proxy IPs (or a test key), otherwise the scenario cannot submit.
- Agreed frequency (15–60 min) and a change process: a website redesign breaks the steps (billed as change work).

## 2. One-time Integrit setup

1. **WebDriver on the external proxy:** run Selenium standalone Chrome next to the proxy, e.g.
   `docker run -d --restart unless-stopped --name selenium -p 127.0.0.1:4444:4444 --shm-size=2g selenium/standalone-chrome:4.27.0`.
   In `zabbix_proxy.conf`: `WebDriverURL=http://127.0.0.1:4444` and `StartBrowserPollers=2`, then restart the proxy.
2. **Test mailbox** (only for the mail check): shared mailbox `webtest@integrit.cz`. Entra app **Integrit Mail Probe** (draft 5.3) with
   application permission `Mail.Read`, restricted to this mailbox with Exchange RBAC for Applications (same commands as MON-BKP INSTALL step 2.3,
   scope `PrimarySmtpAddress -eq 'webtest@integrit.cz'`). Plus addressing (`webtest+…@`) delivers into the same mailbox.

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

## 4. Host (one per scenario)

`<CUST>-WEB-<SCENARIO>`, visible name e.g. `ACME · Kontaktní formulář`: groups `Customers/<CUST>` + `Services/MON-WEB-FUNC`, monitored by the
external proxy, no interface, template `INT MON-WEB-FUNC Scenario`, tags `customer`, `managed`, `tier`, `contract`. Macros:
`{$INT.WEBFUNC.STEPS}`; for the mail check `{$INT.WEBFUNC.MAIL.CHECK}=1`, `{$INT.WEBFUNC.MAIL.APP.ID}`, `{$INT.WEBFUNC.MAIL.SECRET}`,
`{$INT.WEBFUNC.MAIL.SUBJECT}` (regex of the confirmation subject, e.g. `INT-TEST|Nová zpráva z webu`).

## 5. Verify

1. Items → `Scenario: Run` → **Execute now**. Within 2 min `Scenario: Result` = OK and `Scenario: Duration` shows seconds.
2. Break it on purpose: change the `expect` text in the macro to something that does not exist → after two runs (or two Execute now)
   HIGH "failed twice in a row", `Scenario: Failed step` = that step, screenshot visible. Revert the macro.
3. Mail check: after a successful run, `Confirmation mail: Received in window` ≥ 1 within 15 min.
