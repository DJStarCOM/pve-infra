# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Назначение проекта

IaC-репозиторий для управления Proxmox VE 8.4.17 инфраструктурой. Цель — создание и поддержка k3s-кластера на VM внутри Proxmox для запуска рабочих проектов.

## Инфраструктура

- **Сервер:** AMD EPYC 4244P 6C/12T, 64GB RAM, 4x ~894GB NVMe (2 в RAID1 под ОС, 2 в ZFS pool)
- **IP:** 57.128.231.223 (внешний), SSH: `root@57.128.231.223`
- **Сети Proxmox:**
  - `vmbr0` — WAN, внешний IP 57.128.231.223/32
  - `vmbr1` — vRack (не используется пока)
  - `vmbr2` — NAT 10.0.0.0/16, шлюз 10.0.0.1, выход в интернет через MASQUERADE
- **Хранилища:**
  - `local` (dir, ~860GB) — ISO, бэкапы, снипеты
  - `nvme-storage` (ZFS pool, ~860GB) — диски VM

## Стек IaC

| Инструмент | Назначение |
|---|---|
| Terraform + bpg/proxmox provider | Создание VM из cloud-init шаблона |
| Ansible | Подготовка шаблона, настройка VM, установка k3s |

## Доступ

- **SSH к Proxmox:** `ssh -i ~/.ssh/id_ecdsa root@57.128.231.223` (только ECDSA-ключ, RSA не принимается)
- **SSH к VM:** через ProxyJump: `ssh -o ProxyJump=root@57.128.231.223 -i ~/.ssh/id_ecdsa ubuntu@10.0.1.10`
- **PVE API (порт 8006):** закрыт файрволом, нужен SSH-туннель перед запуском Terraform:
  ```bash
  ssh -f -N -L 8006:127.0.0.1:8006 -i ~/.ssh/id_ecdsa root@57.128.231.223
  ```
  Endpoint в terraform.tfvars: `https://127.0.0.1:8006`
- **kubectl:** `export KUBECONFIG=$PWD/kubeconfig.yaml` (требует туннель до 10.0.1.10:6443)

## Команды

```bash
# Фаза 1: Создать cloud-init шаблон на Proxmox
ansible-playbook ansible/playbooks/prepare-template.yml

# Фаза 2: Создать VM через Terraform (сначала поднять SSH-туннель!)
cd terraform && terraform init && terraform plan && terraform apply

# Фаза 3: Настроить VM и установить k3s
ansible-playbook ansible/playbooks/setup-nodes.yml
ansible-playbook ansible/playbooks/install-k3s.yml
```

## K3s-кластер

- **Версия:** v1.34.5+k3s1, Ubuntu 24.04 LTS
- **Master:** 10.0.1.10 (VMID 300), 2 CPU, 4GB RAM
- **Workers:** 10.0.1.11-12 (VMID 301-302), 2 CPU, 8GB RAM каждый
- **Сеть:** vmbr2 (NAT)
- k3s установлен с `--disable traefik --disable servicelb`

## Компоненты кластера

| Компонент | Namespace | Версия | Назначение |
|---|---|---|---|
| Longhorn | longhorn-system | v1.8.1 | Distributed storage (default SC) |
| Traefik | traefik | Helm chart, NodePort 30080/30443 | Ingress controller |
| ArgoCD | argocd | v2.14.11 | GitOps CD |
| cert-manager | cert-manager | v1.17.2 | TLS-сертификаты (Let's Encrypt) |
| kube-prometheus-stack | monitoring | Helm chart 69.8.0 | Мониторинг (Prometheus + Grafana + Alertmanager) |
| Cloudflare Tunnel | cloudflare | cloudflared latest | Внешний доступ к сервисам через webtechforge.dev |

```bash
# Фаза 4: Установить Longhorn + Traefik + ArgoCD
ansible-playbook ansible/playbooks/setup-k3s-infra.yml

# Фаза 5: Установить cert-manager + мониторинг
ansible-playbook ansible/playbooks/setup-k3s-extras.yml

# Фаза 6: Cloudflare Tunnel + Ingress (запросит tunnel token)
ansible-playbook ansible/playbooks/setup-cloudflare-tunnel.yml
```

### Внешний доступ (через Cloudflare Tunnel)

| Сервис | URL |
|---|---|
| Grafana | `https://gf.webtechforge.dev` (admin/admin) |
| Prometheus | `https://prom.webtechforge.dev` |
| ArgoCD | `https://argo.webtechforge.dev` |

Все сервисы защищены Cloudflare Access (Google OAuth, `s.tsepeniuk@webtechforge.dev`). Bypass для health-эндпоинтов и webhooks.

Для добавления нового сервиса: создать Ingress с `host: <sub>.webtechforge.dev` + добавить hostname в CF tunnel config + Access Application.

### Доступ через port-forward (без туннеля)

```bash
kubectl -n monitoring port-forward svc/kube-prometheus-stack-grafana 3000:80
# Открыть http://localhost:3000 (admin/admin)
```

## Язык

Документация, комментарии и коммиты — на русском. Код и конфигурация — на английском.
