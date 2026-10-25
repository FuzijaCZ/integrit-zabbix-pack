#!/usr/bin/env python3
"""Integrit MON-CERT: certificate and CRL checks (Zabbix ExternalScripts on the site proxy).

Usage:
  int-cert-check.py tls <host> <port> <mode>   mode: tls (direct TLS: HTTPS, LDAPS, IMAPS, ...), smtp, ldap (STARTTLS), rdp
  int-cert-check.py crl <url>                  HTTP(S) CRL distribution point (DER or PEM)
Needs: Python 3.7+ (standard library only). Prints one JSON line; problems are reported in "error", never as a traceback.
Chain validation uses the proxy trust store: add the customer's internal root CA there (see INSTALL step 2).
"""
import datetime
import json
import smtplib
import socket
import ssl
import sys
import tempfile
import time
import urllib.request

TIMEOUT = 10


def starttls_socket(host, port, mode):
    """Open TCP, run the protocol-specific STARTTLS preamble, return the raw socket ready for the TLS handshake."""
    if mode == 'smtp':
        s = smtplib.SMTP(host, port, timeout=TIMEOUT)
        s.ehlo('zabbix-probe.integrit.cz')
        if not s.has_extn('starttls'):
            raise RuntimeError('server does not offer STARTTLS')
        code, msg = s.docmd('STARTTLS')
        if code != 220:
            raise RuntimeError('STARTTLS refused: %s %s' % (code, msg))
        return s.sock
    sock = socket.create_connection((host, port), timeout=TIMEOUT)
    if mode == 'ldap':  # ExtendedRequest 1.3.6.1.4.1.1466.20037 (StartTLS)
        oid = b'1.3.6.1.4.1.1466.20037'
        sock.sendall(b'\x30' + bytes([len(oid) + 7]) + b'\x02\x01\x01\x77' + bytes([len(oid) + 2]) + b'\x80' + bytes([len(oid)]) + oid)
        resp = sock.recv(4096)
        if b'\x0a\x01\x00' not in resp[:20]:  # resultCode success
            raise RuntimeError('LDAP StartTLS refused')
    elif mode == 'rdp':  # X.224 Connection Request with RDP_NEG_REQ (TLS | CredSSP)
        sock.sendall(bytes.fromhex('030000130ee000000000000100080003000000'))
        resp = sock.recv(1024)
        if len(resp) < 19 or resp[11] != 0x02:
            raise RuntimeError('RDP server did not accept TLS (standard RDP security only?)')
    return sock


def connect(host, port, mode, ctx):
    sock = socket.create_connection((host, port), timeout=TIMEOUT) if mode == 'tls' else starttls_socket(host, port, mode)
    return ctx.wrap_socket(sock, server_hostname=host)


def name_of(rdn_seq, field='commonName'):
    for rdn in rdn_seq or ():
        for k, v in rdn:
            if k == field:
                return v
    return ''


def check_tls(host, port, mode):
    out = {'error': ''}
    ctx = ssl.create_default_context()
    ctx.check_hostname = False
    ctx.verify_mode = ssl.CERT_NONE
    with connect(host, port, mode, ctx) as s:
        der = s.getpeercert(binary_form=True)
        out['protocol'] = s.version()
    with tempfile.NamedTemporaryFile('w', suffix='.pem') as f:
        f.write(ssl.DER_cert_to_PEM_cert(der))
        f.flush()
        info = ssl._ssl._test_decode_cert(f.name)
    now = time.time()
    out['days'] = int((ssl.cert_time_to_seconds(info['notAfter']) - now) // 86400)
    out['age_days'] = int((now - ssl.cert_time_to_seconds(info['notBefore'])) // 86400)
    out['subject'] = name_of(info.get('subject')) or str(info.get('subject'))
    out['issuer'] = name_of(info.get('issuer')) or name_of(info.get('issuer'), 'organizationName')
    out['self_signed'] = 1 if info.get('subject') == info.get('issuer') else 0
    out['not_after'] = info['notAfter']
    try:  # second session: chain against the proxy trust store + host name
        with connect(host, port, mode, ssl.create_default_context()):
            pass
        out['valid'] = 1
        out['verify_error'] = ''
    except ssl.SSLCertVerificationError as e:
        out['valid'] = 0
        out['verify_error'] = str(e.verify_message or e)
    return out


def der_items(data, pos, end):
    """Yield (tag, content_start, content_end) of DER elements between pos and end."""
    while pos < end:
        tag = data[pos]
        length = data[pos + 1]
        pos += 2
        if length & 0x80:
            n = length & 0x7f
            length = int.from_bytes(data[pos:pos + n], 'big')
            pos += n
        yield tag, pos, pos + length
        pos += length


def der_time(tag, raw):
    s = raw.decode('ascii').rstrip('Z')
    fmt = '%y%m%d%H%M%S' if tag == 0x17 else '%Y%m%d%H%M%S'
    return datetime.datetime.strptime(s, fmt).replace(tzinfo=datetime.timezone.utc).timestamp()


def check_crl(url):
    req = urllib.request.Request(url, headers={'User-Agent': 'Integrit-Zabbix-CRL-check'})
    with urllib.request.urlopen(req, timeout=TIMEOUT) as r:
        data = r.read()
    if data.lstrip().startswith(b'-----BEGIN'):
        import base64
        body = b''.join(l for l in data.splitlines() if l and not l.startswith(b'-----'))
        data = base64.b64decode(body)
    _, s, e = next(der_items(data, 0, len(data)))           # CertificateList
    _, s, e = next(der_items(data, s, e))                   # TBSCertList
    times = [(t, data[a:b]) for t, a, b in der_items(data, s, e) if t in (0x17, 0x18)]
    if not times:
        raise RuntimeError('no thisUpdate in CRL')
    now = time.time()
    out = {'error': '', 'ok': 1, 'age_hours': round((now - der_time(*times[0])) / 3600, 1)}
    out['hours_left'] = round((der_time(*times[1]) - now) / 3600, 1) if len(times) > 1 else None
    return out


def main():
    a = sys.argv[1:]
    try:
        if len(a) == 4 and a[0] == 'tls' and a[3] in ('tls', 'smtp', 'ldap', 'rdp'):
            out = check_tls(a[1], int(a[2]), a[3])
        elif len(a) == 2 and a[0] == 'crl':
            out = check_crl(a[1])
        else:
            out = {'error': 'usage: int-cert-check.py tls <host> <port> tls|smtp|ldap|rdp | crl <url>'}
    except Exception as e:
        out = {'error': '%s: %s' % (type(e).__name__, e), 'ok': 0}
    print(json.dumps(out))


if __name__ == '__main__':
    main()
