#!/usr/bin/env python3
"""Integrit MON-VOIP SIP OPTIONS probe (Zabbix ExternalScripts, Python 3.6+, standard library only).

Usage: int-sip-options.py <host> [port] [udp|tcp|tls] [timeout_s]
Prints one line of JSON: {"code": 200, "reason": "OK", "rtt_ms": 23.4, "error": ""}
code 0 = no SIP answer (timeout, refused, DNS error); details in "error".
"""
import json
import random
import socket
import ssl
import string
import sys
import time


def rand(n=10):
    return ''.join(random.choice(string.ascii_lowercase + string.digits) for _ in range(n))


def build(host, port, transport, local_ip, local_port):
    proto = {'udp': 'UDP', 'tcp': 'TCP', 'tls': 'TLS'}[transport]
    uri = 'sip:%s:%d' % (host, port)
    if transport == 'tls':
        uri = 'sips:%s:%d' % (host, port)
    lines = [
        'OPTIONS %s SIP/2.0' % uri,
        'Via: SIP/2.0/%s %s:%d;branch=z9hG4bK%s;rport' % (proto, local_ip, local_port, rand()),
        'Max-Forwards: 70',
        'To: <%s>' % uri,
        'From: <sip:zabbix@%s>;tag=%s' % (local_ip, rand(8)),
        'Call-ID: %s@%s' % (rand(16), local_ip),
        'CSeq: 1 OPTIONS',
        'Contact: <sip:zabbix@%s:%d>' % (local_ip, local_port),
        'Accept: application/sdp',
        'User-Agent: Integrit-Zabbix-SIP-Probe/1.0',
        'Content-Length: 0',
        '', '']
    return '\r\n'.join(lines).encode()


def parse(data):
    first = data.decode('utf-8', 'replace').split('\r\n', 1)[0]
    parts = first.split(' ', 2)
    if len(parts) < 2 or not parts[0].startswith('SIP/2.0') or not parts[1].isdigit():
        raise ValueError('not a SIP response: %r' % first[:80])
    return int(parts[1]), parts[2] if len(parts) > 2 else ''


def probe(host, port, transport, timeout):
    addr = socket.getaddrinfo(host, port, socket.AF_INET, socket.SOCK_DGRAM if transport == 'udp' else socket.SOCK_STREAM)[0][4]
    if transport == 'udp':
        s = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
        try:
            s.connect(addr)
            local_ip, local_port = s.getsockname()
            msg = build(host, port, transport, local_ip, local_port)
            deadline = time.time() + timeout
            tries = 0
            while True:
                start = time.time()
                s.send(msg)
                tries += 1
                s.settimeout(min(1.0 * tries, max(0.1, deadline - time.time())))
                try:
                    while True:
                        data = s.recv(65535)
                        code, reason = parse(data)
                        if code >= 200 or code < 100:
                            return code, reason, (time.time() - start) * 1000
                except socket.timeout:
                    if time.time() >= deadline:
                        raise
        finally:
            s.close()
    raw = socket.create_connection(addr, timeout=timeout)
    try:
        s = ssl.create_default_context().wrap_socket(raw, server_hostname=host) if transport == 'tls' else raw
        s.settimeout(timeout)
        local_ip, local_port = s.getsockname()
        start = time.time()
        s.sendall(build(host, port, transport, local_ip, local_port))
        buf = b''
        while b'\r\n\r\n' not in buf:
            chunk = s.recv(65535)
            if not chunk:
                break
            buf += chunk
            code, reason = parse(buf)
            if code < 200 and b'\r\n\r\n' in buf:
                buf = buf.split(b'\r\n\r\n', 1)[1]
        code, reason = parse(buf)
        return code, reason, (time.time() - start) * 1000
    finally:
        raw.close()


def main():
    host = sys.argv[1] if len(sys.argv) > 1 else ''
    transport = (sys.argv[3] if len(sys.argv) > 3 and sys.argv[3] else 'udp').lower()
    port = int(sys.argv[2]) if len(sys.argv) > 2 and sys.argv[2] else (5061 if transport == 'tls' else 5060)
    timeout = float(sys.argv[4]) if len(sys.argv) > 4 and sys.argv[4] else 4.0
    out = {'code': 0, 'reason': '', 'rtt_ms': 0, 'error': ''}
    try:
        if not host or transport not in ('udp', 'tcp', 'tls'):
            raise ValueError('usage: int-sip-options.py <host> [port] [udp|tcp|tls] [timeout_s]')
        code, reason, rtt = probe(host, port, transport, timeout)
        out.update(code=code, reason=reason.strip(), rtt_ms=round(rtt, 1))
    except Exception as e:  # every failure becomes code 0 with a reason, never a traceback
        out['error'] = '%s: %s' % (type(e).__name__, e)
    print(json.dumps(out))


if __name__ == '__main__':
    main()
