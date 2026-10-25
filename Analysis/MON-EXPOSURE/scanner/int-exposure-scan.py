#!/usr/bin/env python3
"""Integrit MON-EXPOSURE weekly scanner (runs on the dedicated Integrit scan VM, NOT on a Zabbix proxy).

1. Reads the hosts linked to template 'INT MON-EXPOSURE Public IP' from the Zabbix API (read-only token): host name + interface IP.
2. Per IP: nmap TCP top ports + selected UDP ports, then version-light + ssl-enum-ciphers on the open TCP ports.
3. Sends one JSON per host with zabbix_sender to the trapper item int.exp.scan (via the proxy that monitors the host).

Config: /etc/integrit/exposure.json (see exposure.json.example). Needs: Python 3.7+, nmap 7.80+, zabbix_sender. Run as root (UDP scan).
Only scan IPs with written customer consent (contract annex). Usage: int-exposure-scan.py [--dry-run] [--host <zabbix host name>]
"""
import json
import subprocess
import sys
import tempfile
import time
import urllib.request
import xml.etree.ElementTree as ET

CONFIG = '/etc/integrit/exposure.json'


def api(cfg, method, params):
    req = urllib.request.Request(cfg['zabbix_api_url'], data=json.dumps({'jsonrpc': '2.0', 'method': method, 'params': params, 'id': 1}).encode(),
                                 headers={'Content-Type': 'application/json-rpc', 'Authorization': 'Bearer ' + cfg['api_token']})
    with urllib.request.urlopen(req, timeout=30) as r:
        res = json.load(r)
    if 'error' in res:
        raise RuntimeError('%s: %s %s' % (method, res['error'].get('message'), res['error'].get('data')))
    return res['result']


def targets(cfg):
    tpl = api(cfg, 'template.get', {'output': ['templateid'], 'filter': {'host': [cfg.get('template', 'INT MON-EXPOSURE Public IP')]}})
    if not tpl:
        raise RuntimeError('template not found')
    hosts = api(cfg, 'host.get', {'output': ['host', 'status'], 'templateids': tpl[0]['templateid'], 'selectInterfaces': ['ip', 'main'],
                                  'filter': {'status': 0}})
    out = []
    for h in hosts:
        ips = [i['ip'] for i in h['interfaces'] if i['main'] == '1' and i['ip']]
        if ips:
            out.append((h['host'], ips[0]))
    return out


def nmap(args):
    return ET.fromstring(subprocess.run(['nmap', '-oX', '-'] + args, stdout=subprocess.PIPE, stderr=subprocess.PIPE,
                                        check=True, timeout=3600).stdout)


def scan(cfg, ip):
    res = {'scan_time': int(time.time()), 'tcp_open': [], 'udp_open': [], 'services': {}, 'tls': {}, 'error': ''}
    x = nmap(['-Pn', '-n', '-sT', '-T3', '--open', '--top-ports', str(cfg.get('tcp_top_ports', 1000)), ip])
    res['tcp_open'] = sorted(int(p.get('portid')) for p in x.iter('port') if p.find('state').get('state') == 'open')
    udp = cfg.get('udp_ports', '161,500,1194,1900,5060,11211')
    if udp:
        x = nmap(['-Pn', '-n', '-sU', '-T3', '--open', '-p', udp, ip])
        res['udp_open'] = sorted(int(p.get('portid')) for p in x.iter('port') if p.find('state').get('state') == 'open')  # open|filtered not counted
    if res['tcp_open']:
        x = nmap(['-Pn', '-n', '-sT', '-sV', '--version-light', '--script', 'ssl-enum-ciphers',
                  '-p', ','.join(map(str, res['tcp_open'])), ip])
        for p in x.iter('port'):
            port = p.get('portid')
            svc = p.find('service')
            if svc is not None:
                res['services'][port] = ' '.join(filter(None, [svc.get('name'), svc.get('product'), svc.get('version')]))[:80]
            for s in p.iter('script'):
                if s.get('id') != 'ssl-enum-ciphers':
                    continue
                protos = [t.get('key') for t in s.findall('table') if t.get('key', '').startswith(('TLS', 'SSL'))]
                grade = [e.text for e in s.findall('elem') if e.get('key') == 'least strength']
                res['tls'][port] = {'protocols': protos, 'grade': grade[0] if grade else ''}
    return res


def send(cfg, host, data, dry):
    line = '"%s" int.exp.scan %s\n' % (host.replace('"', '\\"'), json.dumps(json.dumps(data, separators=(',', ':'))))
    if dry:
        print(line, end='')
        return
    with tempfile.NamedTemporaryFile('w', suffix='.txt') as f:
        f.write(line)
        f.flush()
        z, port = cfg['sender_target'].rsplit(':', 1)
        subprocess.run(['zabbix_sender', '-z', z, '-p', port, '-i', f.name] + cfg.get('sender_args', []), check=True,
                       stdout=subprocess.DEVNULL, timeout=60)


def main():
    dry = '--dry-run' in sys.argv
    only = sys.argv[sys.argv.index('--host') + 1] if '--host' in sys.argv else None
    cfg = json.load(open(CONFIG))
    failed = 0
    for host, ip in targets(cfg):
        if only and host != only:
            continue
        try:
            data = scan(cfg, ip)
        except Exception as e:  # report the error to Zabbix, continue with the next IP
            data = {'scan_time': int(time.time()), 'error': '%s: %s' % (type(e).__name__, e)}
            failed += 1
        send(cfg, host, data, dry)
    sys.exit(1 if failed else 0)


if __name__ == '__main__':
    main()
