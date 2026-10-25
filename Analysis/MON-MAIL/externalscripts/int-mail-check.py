#!/usr/bin/env python3
"""Integrit MON-MAIL Basic: mail domain security check from outside (Zabbix ExternalScripts on the external proxy).

Usage: int-mail-check.py <domain> [dkim-selectors,comma] [outbound-ips,comma] [spamhaus-dqs-key]
Needs: Python 3.6+, `dig` (Debian/Ubuntu package dnsutils / bind9-dnsutils), outbound TCP 25.
Prints one JSON line. Every check fails soft: problems are reported as values, never as a traceback.
"""
import json
import re
import shutil
import smtplib
import socket
import ssl
import subprocess
import sys
import tempfile
import time

TIMEOUT = 8
DNSBL = {  # zone -> weight: major lists raise HIGH, minor WARNING (template triggers)
    'b.barracudacentral.org': 'major',
    'bl.spamcop.net': 'minor',
    'dnsbl-1.uceprotect.net': 'minor',
}


def dig(name, rtype):
    try:
        out = subprocess.run(['dig', '+short', '+time=3', '+tries=2', rtype, name],
                             stdout=subprocess.PIPE, stderr=subprocess.DEVNULL, timeout=15, universal_newlines=True).stdout
    except Exception:
        return []
    lines = [l.strip() for l in out.splitlines() if l.strip() and not l.startswith(';')]
    if rtype == 'TXT':
        return [''.join(re.findall(r'"((?:[^"\\]|\\.)*)"', l)) for l in lines]
    return lines


def spf_lookups(domain, depth=0, seen=None):
    """Return (record, lookup_count, all_qualifier, error) following include/redirect recursively (RFC 7208 limit 10)."""
    seen = seen or set()
    if domain in seen or depth > 10:
        return None, 0, '', 'loop'
    seen.add(domain)
    recs = [t for t in dig(domain, 'TXT') if t.lower().startswith('v=spf1')]
    if not recs:
        return None, 0, '', 'missing' if depth == 0 else 'include %s has no SPF' % domain
    if len(recs) > 1:
        return recs[0], 0, '', 'multiple SPF records'
    rec, count, allq, err = recs[0], 0, '', ''
    for term in rec.split()[1:]:
        t = term.lower().lstrip('+-~?')
        if t.startswith(('a', 'mx', 'ptr', 'exists:')) and not t.startswith('all'):
            count += 1
        elif t.startswith('include:') or t.startswith('redirect='):
            count += 1
            sub = term.split(':', 1)[1] if ':' in term else term.split('=', 1)[1]
            _, c, _, e = spf_lookups(sub, depth + 1, seen)
            count += c
            err = err or e
        elif t == 'all':
            allq = term[0] if term[0] in '+-~?' else '+'
    return rec, count, allq, err


def smtp_check(mx):
    res = {'mx': mx, 'banner': 0, 'starttls': 0, 'cert_valid': 0, 'cert_days': None, 'error': ''}
    try:
        s = smtplib.SMTP(timeout=TIMEOUT)
        code, _ = s.connect(mx, 25)
        res['banner'] = 1 if code == 220 else 0
        s.ehlo('zabbix-probe.integrit.cz')
        if s.has_extn('starttls'):
            ctx = ssl.create_default_context()
            ctx.check_hostname = False
            ctx.verify_mode = ssl.CERT_NONE
            s.starttls(context=ctx)
            res['starttls'] = 1
            der = s.sock.getpeercert(binary_form=True)
            with tempfile.NamedTemporaryFile('w', suffix='.pem') as f:
                f.write(ssl.DER_cert_to_PEM_cert(der))
                f.flush()
                info = ssl._ssl._test_decode_cert(f.name)
            res['cert_days'] = int((ssl.cert_time_to_seconds(info['notAfter']) - time.time()) // 86400)
            try:  # chain + MX host name validation in a second session with a verifying context
                v = smtplib.SMTP(mx, 25, timeout=TIMEOUT)
                v.ehlo('zabbix-probe.integrit.cz')
                v.starttls(context=ssl.create_default_context())
                res['cert_valid'] = 1
                v.quit()
            except Exception as e:
                res['error'] = 'cert: %s' % e
        s.quit()
    except Exception as e:
        res['error'] = '%s: %s' % (type(e).__name__, e)
    return res


def main():
    domain = (sys.argv[1] if len(sys.argv) > 1 else '').strip().lower()
    selectors = [x for x in (sys.argv[2] if len(sys.argv) > 2 else '').split(',') if x.strip()]
    ips = [x.strip() for x in (sys.argv[3] if len(sys.argv) > 3 else '').split(',') if x.strip()]
    dqs = (sys.argv[4] if len(sys.argv) > 4 else '').strip()
    out = {'domain': domain}
    if not domain:
        print(json.dumps({'error': 'usage: int-mail-check.py <domain> [selectors] [ips] [dqs-key]'}))
        return

    if not shutil.which('dig'):
        print(json.dumps({'domain': domain, 'error': 'dig not installed (apt install bind9-dnsutils)'}))
        return
    if not dig(domain, 'NS'):
        print(json.dumps({'domain': domain, 'error': 'DNS lookup of NS records failed (resolver problem or domain does not exist)'}))
        return
    out['error'] = ''
    mx = sorted((int(p), h.rstrip('.')) for p, h in (l.split() for l in dig(domain, 'MX') if len(l.split()) == 2))
    out['mx_count'] = len(mx)
    checks = [smtp_check(h) for _, h in mx[:3]]
    out['mx'] = checks
    out['mx_reachable'] = sum(1 for c in checks if c['banner'])
    days = [c['cert_days'] for c in checks if c['cert_days'] is not None]
    out['starttls_min_days'] = min(days) if days else None
    out['starttls_missing'] = sum(1 for c in checks if c['banner'] and not c['starttls'])
    out['starttls_invalid'] = sum(1 for c in checks if c['starttls'] and not c['cert_valid'])

    rec, lookups, allq, err = spf_lookups(domain)
    out['spf'] = rec or ''
    out['spf_ok'] = 1 if rec and not err and lookups <= 10 and allq in ('-', '~') else 0
    out['spf_lookups'] = lookups
    out['spf_error'] = err or ('more than 10 DNS lookups' if lookups > 10 else ('no -all/~all' if rec and allq not in ('-', '~') else ''))

    dm = [t for t in dig('_dmarc.' + domain, 'TXT') if t.lower().startswith('v=dmarc1')]
    pol = re.search(r'\bp=(\w+)', dm[0], re.I).group(1).lower() if dm and re.search(r'\bp=(\w+)', dm[0], re.I) else ''
    out['dmarc'] = dm[0] if dm else ''
    out['dmarc_policy'] = {'reject': 3, 'quarantine': 2, 'none': 1}.get(pol, 0)

    out['dkim_missing'] = [s for s in selectors if not any('p=' in t for t in dig('%s._domainkey.%s' % (s.strip(), domain), 'TXT'))
                           and not dig('%s._domainkey.%s' % (s.strip(), domain), 'CNAME')]
    out['dkim_missing_count'] = len(out['dkim_missing'])
    out['dkim_missing'] = ', '.join(out['dkim_missing'])
    out['mta_sts'] = 1 if any(t.lower().startswith('v=stsv1') for t in dig('_mta-sts.' + domain, 'TXT')) else 0

    listed_major, listed_minor, hits = 0, 0, []
    zones = dict(DNSBL)
    if dqs:
        zones['%s.zen.dq.spamhaus.net' % dqs] = 'major'
    for ip in ips:
        rev = '.'.join(reversed(ip.split('.')))
        for zone, weight in zones.items():
            ans = [a for a in dig('%s.%s' % (rev, zone), 'A') if a.startswith('127.')]
            # Spamhaus 127.255.255.x and similar = query refused / error, not a listing
            ans = [a for a in ans if not a.startswith('127.255.255.')]
            if ans:
                hits.append('%s@%s' % (ip, zone.split('.zen.')[-1] if 'spamhaus' in zone else zone))
                if weight == 'major':
                    listed_major += 1
                else:
                    listed_minor += 1
    out['bl_major'] = listed_major
    out['bl_minor'] = listed_minor
    out['bl_hits'] = ', '.join(hits)
    print(json.dumps(out))


if __name__ == '__main__':
    main()
