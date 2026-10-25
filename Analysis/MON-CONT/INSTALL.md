# MON-CONT: containers (Docker; Kubernetes as a project): installation

Version 1.0 · Zabbix 7.0.31. Draft reference: section 5.6.15.

Draft recommendation: not part of the first release; offer Docker hosts on request (MON-SRV + this template) and Kubernetes as a
project (MON-CUSTOM pricing) until at least 3 customers need it.

| Template | Linked on |
|---|---|
| `INT MON-CONT Docker` | Docker hosts (Linux, agent 2 **active**), next to `INT MON-SRV Linux` |

The official `Docker by Zabbix agent 2` is not linked: all its items are **passive**, and Integrit agents are active-only (no inbound
port 10050 on customer servers). `INT MON-CONT Docker` uses the same agent 2 Docker plugin keys as active checks.

## Files

| File | Where |
|---|---|
| `template_int_mon_cont.yaml` | Zabbix import |

## Triggers

| Trigger | Severity | Default |
|---|---|---|
| Docker daemon not responding | HIGH | 3 checks |
| Container not running | AVERAGE | 5 min; per container `{$INT.CONT.EXPECTED:"<name>"}=0` for containers that may be stopped |
| Container unhealthy (HEALTHCHECK) | AVERAGE | 2 values in 5 min |
| Container restart loop | HIGH | > 3 restarts in 15 min |

All container triggers depend on the daemon trigger. Host CPU / memory / disk (including `/var/lib/docker`): MON-SRV.
Not in v1.0: per-container CPU / memory (report later), image updates, Docker Swarm.

## 1. What the customer provides

- Which containers are production (expected running) and which are one-off jobs / may be stopped.

## 2. Agent

The Docker plugin is built into agent 2. Give the agent access to the socket:
```
usermod -aG docker zabbix
systemctl restart zabbix-agent2
```
(Membership of the `docker` group is root-equivalent on that host: acceptable for the Integrit agent with remote commands disabled,
draft 3.1.7; document it for the customer.) Test: `zabbix_agent2 -t docker.ping` → `1`.

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

Link `INT MON-CONT Docker` on the MON-SRV Linux host, add group `Services/MON-CONT`. Optional macros:
`{$INT.CONT.NAME.NOT_MATCHES}` (e.g. `^(certbot|migrate-.*)$`), `{$INT.CONT.EXPECTED:"watchtower"}=0`.

## 5. Kubernetes (project, not a template in v1.0)

Use the official Zabbix Helm chart (`zabbix-helm-chrt`, release 7.0) per cluster: a Zabbix proxy **inside the cluster** (active,
outbound to Integrit), kube-state-metrics and agents; then the official templates `Kubernetes nodes by HTTP`,
`Kubernetes cluster state by HTTP`, `Kubernetes API server by HTTP`, `Kubernetes Kubelet by HTTP` (+ controller manager / scheduler
for self-managed control planes). Multi-tenancy: the discovered node / component hosts must get the customer's groups and tags
(set the host group / tag macros in the Helm values and check after the first discovery). Managed clusters (AKS / EKS): combine with
MON-CLOUD. Budget 4–8 h per cluster (draft 5.6.15 point 9).

## 6. Verify

1. Latest data: `Docker: ping` = up, `Docker: containers running` = `docker ps -q | wc -l`.
2. One `Container <name>: running` item per container; `docker stop <test container>` → AVERAGE after 5 min; start it again.

Not tested against a live Docker host here; JSON paths follow the Docker Engine API (`/containers/<id>/json`).
