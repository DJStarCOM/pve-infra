# CLAUDE.md

## Назначение

IaC-репозиторий для Proxmox VE 8.4.17: Terraform создаёт VM, Ansible настраивает k3s-кластер.

## Доступ

- **SSH к Proxmox:** `ssh -i ~/.ssh/id_ecdsa root@57.128.231.223` (только ECDSA-ключ)
- **SSH к VM:** `ssh -o ProxyJump=root@57.128.231.223 -i ~/.ssh/id_ecdsa ubuntu@10.0.1.10`
- **PVE API:** закрыт файрволом, нужен SSH-туннель:
  ```bash
  ssh -f -N -L 8006:127.0.0.1:8006 -i ~/.ssh/id_ecdsa root@57.128.231.223
  ```
- **kubectl:** `export KUBECONFIG=$PWD/kubeconfig.yaml`

## Сеть и ноды

- `vmbr2` — NAT 10.0.0.0/16, шлюз 10.0.0.1
- Master: 10.0.1.10, Workers: 10.0.1.11-12
- k3s с `--disable traefik --disable servicelb`

## Команды

```bash
# Фаза 1: cloud-init шаблон
ansible-playbook ansible/playbooks/prepare-template.yml

# Фаза 2: VM через Terraform (сначала SSH-туннель!)
cd terraform && terraform init && terraform plan && terraform apply

# Фаза 3: Настройка VM + k3s
ansible-playbook ansible/playbooks/setup-nodes.yml
ansible-playbook ansible/playbooks/install-k3s.yml

# Фаза 4: Longhorn + Traefik + ArgoCD
ansible-playbook ansible/playbooks/setup-k3s-infra.yml

# Фаза 5: cert-manager + мониторинг
ansible-playbook ansible/playbooks/setup-k3s-extras.yml

# Фаза 6: Cloudflare Tunnel
ansible-playbook ansible/playbooks/setup-cloudflare-tunnel.yml

# Фаза 7: ArgoCD GitOps (deploy key + webhook + App of Apps)
ansible-playbook ansible/playbooks/setup-argocd.yml

# Фаза 8: Open WebUI (сначала создать .secrets/openai!)
ansible-playbook ansible/playbooks/setup-open-webui.yml

# Фаза 9: LiteLLM Proxy + Langfuse (сначала создать .secrets/litellm и .secrets/langfuse!)
ansible-playbook ansible/playbooks/setup-llm-stack.yml
```

## Cloudflare

Секреты для CF API: `.secrets/cloudflare` (CLOUDFLARE_API_TOKEN, ACCOUNT_ID, ZONE_ID, TUNNEL_ID).
Секреты LiteLLM: `.secrets/litellm` (LITELLM_MASTER_KEY, LITELLM_SALT_KEY, AWS_*, OPENROUTER_API_KEY, LANGFUSE_*).
Секреты Langfuse: `.secrets/langfuse` (NEXTAUTH_SECRET, SALT, ENCRYPTION_KEY).
Tunnel name: `k3s-pve`. Все сервисы через Cloudflare Access (Google OAuth).

## ArgoCD GitOps

App of Apps: корневой `root` следит за `argocd/apps/`, auto-sync + selfHeal + prune.
Системные приложения: `system-apps` следит за `argocd/system-apps/` (Helm charts и т.п.).

Добавить приложение: скопировать `argocd/templates/app-example.yml` → `argocd/apps/<name>.yml`, заполнить, закоммитить в main.

## Язык

Документация, комментарии и коммиты — на русском. Код и конфигурация — на английском.
