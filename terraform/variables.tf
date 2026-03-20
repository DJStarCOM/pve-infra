variable "pve_host" {
  description = "Proxmox VE API endpoint"
  type        = string
  default     = "https://57.128.231.223:8006"
}

variable "pve_node" {
  description = "Proxmox node name"
  type        = string
  default     = "pve"
}

variable "pve_api_token" {
  description = "Proxmox API token (format: user@realm!tokenid=secret)"
  type        = string
  sensitive   = true
}

# --- Cloud-init template ---

variable "ci_template_vmid" {
  description = "VMID для cloud-init шаблона"
  type        = number
  default     = 9000
}

variable "ci_template_name" {
  description = "Имя cloud-init шаблона"
  type        = string
  default     = "ubuntu-2404-cloudinit"
}

# --- K3s cluster VMs ---

variable "k3s_master" {
  description = "Конфигурация master-ноды"
  type = object({
    vmid   = number
    name   = string
    cores  = number
    memory = number
    disk   = string
    ip     = string
  })
  default = {
    vmid   = 300
    name   = "k3s-master"
    cores  = 2
    memory = 4096
    disk   = "32G"
    ip     = "10.0.1.10/16"
  }
}

variable "k3s_workers" {
  description = "Конфигурация worker-нод"
  type = list(object({
    vmid   = number
    name   = string
    cores  = number
    memory = number
    disk   = string
    ip     = string
  }))
  default = [
    {
      vmid   = 301
      name   = "k3s-worker-1"
      cores  = 2
      memory = 8192
      disk   = "50G"
      ip     = "10.0.1.11/16"
    },
    {
      vmid   = 302
      name   = "k3s-worker-2"
      cores  = 2
      memory = 8192
      disk   = "50G"
      ip     = "10.0.1.12/16"
    },
  ]
}

variable "gateway" {
  description = "Шлюз для NAT-сети (vmbr2)"
  type        = string
  default     = "10.0.0.1"
}

variable "nameserver" {
  description = "DNS-сервер для VM"
  type        = string
  default     = "1.1.1.1"
}

variable "ssh_public_key" {
  description = "SSH public key для доступа к VM"
  type        = string
}

variable "storage" {
  description = "Хранилище для VM дисков"
  type        = string
  default     = "nvme-storage"
}

variable "bridge" {
  description = "Сетевой мост для VM (NAT-сеть)"
  type        = string
  default     = "vmbr2"
}
