#!/usr/bin/env python3
"""Integrit MON-BKP e-mail parser.

Reads backup report mails from one mailbox via Microsoft Graph (application permission Mail.Read,
limited to that mailbox by Exchange RBAC for Applications), maps each mail to a Zabbix host by
plus-addressing (backup-reports+<HOST>@integrit.cz), parses job name and result from the subject
with rules from bkp-mail-rules.json and sends the values with zabbix_sender to the trapper items of
template "INT MON-BKP E-mail reports". Parser health goes to template "INT MON-BKP E-mail parser".

Python 3.9+, standard library only. Runs every 5 minutes from a systemd timer on the external proxy.

  int-bkp-mail-parser.py [--config /etc/integrit/bkp-mail-parser.json] [--dry-run]
  int-bkp-mail-parser.py --test-subject "[Failed] Daily backup (3 VMs) 1 failed"
"""
import argparse
import json
import os
import re
import subprocess
import sys
import tempfile
import time
import urllib.error
import urllib.parse
import urllib.request
from datetime import datetime, timedelta, timezone

DEFAULT_CONFIG = '/etc/integrit/bkp-mail-parser.json'
RESULT_CODES = {'Success': 0, 'Warning': 1, 'Failed': 2}
GRAPH = 'https://graph.microsoft.com/v1.0'


def load_json(path, default=None):
    try:
        with open(path, encoding='utf-8') as f:
            return json.load(f)
    except FileNotFoundError:
        if default is not None:
            return default
        raise


def save_json(path, data):
    os.makedirs(os.path.dirname(path), exist_ok=True)
    fd, tmp = tempfile.mkstemp(dir=os.path.dirname(path))
    with os.fdopen(fd, 'w', encoding='utf-8') as f:
        json.dump(data, f, indent=1, sort_keys=True)
    os.replace(tmp, path)


class Rules:
    def __init__(self, path):
        data = load_json(path)
        self.result_map = [(re.compile(p, re.I), r) for p, r in data['result_map']]
        self.rules = []
        for rule in data['rules']:
            rmap = [(re.compile(p, re.I), r) for p, r in rule.get('result_map', [])] or self.result_map
            self.rules.append((rule['name'], re.compile(rule['subject']), rmap))

    def parse(self, subject):
        """Return (job, result, rule name) or None."""
        subject = ' '.join(subject.split())
        for name, rx, rmap in self.rules:
            m = rx.search(subject)
            if not m:
                continue
            text = m.group('result')
            for prx, result in rmap:
                if prx.search(text):
                    return clean_job(m.group('job')), result, name
        return None


def clean_job(job):
    # Job name ends up inside a quoted item key parameter: no quotes, brackets or backslashes.
    job = re.sub(r'["\[\]\\]', '_', job.strip())
    return job[:200]


def host_from_recipients(msg, local_part):
    rx = re.compile(r'^' + re.escape(local_part) + r'\+([A-Za-z0-9._ -]+)@', re.I)
    for field in ('toRecipients', 'ccRecipients'):
        for r in msg.get(field) or []:
            m = rx.match((r.get('emailAddress') or {}).get('address', ''))
            if m:
                return m.group(1)
    return None


class Graph:
    def __init__(self, cfg):
        self.cfg = cfg
        self.token = None

    def _request(self, url, data=None, headers=None):
        req = urllib.request.Request(url, data=data, headers=headers or {})
        for attempt in range(4):
            try:
                with urllib.request.urlopen(req, timeout=60) as resp:
                    return json.load(resp)
            except urllib.error.HTTPError as e:
                if e.code in (429, 503, 504) and attempt < 3:
                    time.sleep(int(e.headers.get('Retry-After', 5 * (attempt + 1))))
                    continue
                body = e.read().decode('utf-8', 'replace')[:300]
                raise RuntimeError(f'Graph HTTP {e.code}: {body}') from None

    def login(self):
        with open(self.cfg['client_secret_file'], encoding='utf-8') as f:
            secret = f.read().strip()
        data = urllib.parse.urlencode({
            'grant_type': 'client_credentials',
            'client_id': self.cfg['client_id'],
            'client_secret': secret,
            'scope': 'https://graph.microsoft.com/.default',
        }).encode()
        url = f'https://login.microsoftonline.com/{self.cfg["tenant_id"]}/oauth2/v2.0/token'
        self.token = self._request(url, data=data)['access_token']

    def messages_since(self, since):
        mailbox = urllib.parse.quote(self.cfg['mailbox'])
        params = urllib.parse.urlencode({
            '$filter': f'receivedDateTime ge {since.strftime("%Y-%m-%dT%H:%M:%SZ")}',
            '$orderby': 'receivedDateTime asc',
            '$select': 'id,subject,receivedDateTime,toRecipients,ccRecipients',
            '$top': '100',
        })
        url = f'{GRAPH}/users/{mailbox}/mailFolders/inbox/messages?{params}'
        while url:
            page = self._request(url, headers={'Authorization': 'Bearer ' + self.token})
            yield from page.get('value', [])
            url = page.get('@odata.nextLink')


def q(s):
    """Quote a field for a zabbix_sender input file."""
    return '"' + str(s).replace('\\', '\\\\').replace('"', '\\"') + '"'


def zabbix_send(cfg, lines, dry_run):
    """lines: list of (host, key, ts, value). Returns (processed, failed)."""
    if not lines:
        return 0, 0
    body = ''.join(f'{q(h)} {q(k)} {int(ts)} {q(v)}\n' for h, k, ts, v in lines)
    if dry_run:
        sys.stdout.write(body)
        return len(lines), 0
    with tempfile.NamedTemporaryFile('w', encoding='utf-8', suffix='.txt', delete=False) as f:
        f.write(body)
        path = f.name
    cmd = [cfg.get('zabbix_sender', '/usr/bin/zabbix_sender'), '-z', cfg['zabbix_server'],
           '-p', str(cfg.get('zabbix_port', 10051)), '-T', '-i', path]
    if cfg.get('tls_psk_identity'):
        cmd += ['--tls-connect', 'psk', '--tls-psk-identity', cfg['tls_psk_identity'],
                '--tls-psk-file', cfg['tls_psk_file']]
    try:
        out = subprocess.run(cmd, capture_output=True, text=True, timeout=120)
    finally:
        os.unlink(path)
    m = re.search(r'processed:\s*(\d+);\s*failed:\s*(\d+)', out.stdout)
    if not m:
        raise RuntimeError(f'zabbix_sender: {(out.stdout + out.stderr).strip()[:300]}')
    return int(m.group(1)), int(m.group(2))


def run(cfg, rules, dry_run):
    state = load_json(cfg['state_file'], default={'processed': {}, 'jobs': {}})
    now = datetime.now(timezone.utc)
    lookback = now - timedelta(hours=cfg.get('lookback_hours', 72))
    # Forget processed message ids older than the lookback window.
    state['processed'] = {k: v for k, v in state['processed'].items() if v >= lookback.timestamp()}

    graph = Graph(cfg)
    graph.login()

    per_host = {}      # host -> list of (msg_id, ts, job, result, subject)
    unmatched = []
    for msg in graph.messages_since(lookback):
        if msg['id'] in state['processed']:
            continue
        ts = datetime.strptime(msg['receivedDateTime'][:19], '%Y-%m-%dT%H:%M:%S').replace(tzinfo=timezone.utc).timestamp()
        subject = msg.get('subject') or ''
        host = host_from_recipients(msg, cfg.get('recipient_local_part', 'backup-reports'))
        parsed = rules.parse(subject) if host else None
        if not parsed:
            unmatched.append(f'{host or "<no +HOST in recipient>"}: {subject}')
            state['processed'][msg['id']] = ts
            continue
        job, result, _ = parsed
        per_host.setdefault(host, []).append((msg['id'], ts, job, result, subject))

    errors = []
    for host, reports in per_host.items():
        known = set(state['jobs'].get(host, []))
        new_jobs = {r[2] for r in reports} - known
        if new_jobs:
            # Send discovery first; values for new items are sent on the next run after LLD created them.
            alljobs = sorted(known | new_jobs)
            lld = json.dumps([{'{#JOB}': j} for j in alljobs], ensure_ascii=False)
            ok, failed = zabbix_send(cfg, [(host, 'int.bkp.mail.discovery', now.timestamp(), lld)], dry_run)
            if failed:
                errors.append(f'{host}: discovery rejected (host or template missing?)')
                continue
            state['jobs'][host] = alljobs
            reports = [r for r in reports if r[2] in known]
        lines = []
        for _, ts, job, result, subject in reports:
            lines.append((host, f'int.bkp.mail.result["{job}"]', ts, RESULT_CODES[result]))
            lines.append((host, f'int.bkp.mail.message["{job}"]', ts, subject))
            if result == 'Success':
                lines.append((host, f'int.bkp.mail.lastsuccess["{job}"]', ts, int(ts)))
        if lines:
            ok, failed = zabbix_send(cfg, lines, dry_run)
            if failed:
                errors.append(f'{host}: {failed} of {ok + failed} values rejected')
                continue
            for msg_id, ts, *_ in reports:
                state['processed'][msg_id] = ts

    if not dry_run:
        save_json(cfg['state_file'], state)
    return unmatched, errors


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('--config', default=DEFAULT_CONFIG)
    ap.add_argument('--dry-run', action='store_true', help='print sender lines, do not send or save state')
    ap.add_argument('--test-subject', help='only parse this subject with the rules and print the result')
    args = ap.parse_args()

    cfg = load_json(args.config) if not args.test_subject or os.path.exists(args.config) else {}
    rules_path = cfg.get('rules_file', os.path.join(os.path.dirname(os.path.abspath(__file__)), 'bkp-mail-rules.json'))
    rules = Rules(rules_path)

    if args.test_subject:
        print(rules.parse(args.test_subject) or 'NO MATCH')
        return 0

    platform = cfg['platform_host']
    now = time.time()
    try:
        unmatched, errors = run(cfg, rules, args.dry_run)
    except Exception as e:  # report every failure to Zabbix, then exit non-zero for systemd
        unmatched, errors = [], [f'{type(e).__name__}: {e}']
    health = [(platform, 'int.bkp.mail.parser.heartbeat', now, int(now)),
              (platform, 'int.bkp.mail.parser.unmatched', now, len(unmatched)),
              (platform, 'int.bkp.mail.parser.error', now, '; '.join(errors)[:2000])]
    if unmatched:
        health.append((platform, 'int.bkp.mail.parser.unmatched.last', now, unmatched[-1][:2000]))
    try:
        zabbix_send(cfg, health, args.dry_run)
    except Exception as e:
        errors.append(f'health send failed: {e}')
    for line in unmatched:
        print('UNMATCHED', line, file=sys.stderr)
    for line in errors:
        print('ERROR', line, file=sys.stderr)
    return 1 if errors else 0


if __name__ == '__main__':
    sys.exit(main())
