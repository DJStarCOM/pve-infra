terraform {
  required_version = ">= 1.5.0"

  required_providers {
    proxmox = {
      source  = "bpg/proxmox"
      version = "~> 0.74"
    }
  }
}

provider "proxmox" {
  endpoint = var.pve_host
  api_token = var.pve_api_token
  insecure = true

  ssh {
    agent = true
  }
}

# --- K3s Master ---

resource "proxmox_virtual_environment_vm" "k3s_master" {
  node_name = var.pve_node
  vm_id     = var.k3s_master.vmid
  name      = var.k3s_master.name

  clone {
    vm_id = var.ci_template_vmid
    full  = true
  }

  cpu {
    cores = var.k3s_master.cores
    type  = "host"
  }

  memory {
    dedicated = var.k3s_master.memory
  }

  disk {
    datastore_id = var.storage
    interface    = "scsi0"
    size         = tonumber(replace(var.k3s_master.disk, "G", ""))
  }

  network_device {
    bridge = var.bridge
  }

  initialization {
    datastore_id = "local"

    ip_config {
      ipv4 {
        address = var.k3s_master.ip
        gateway = var.gateway
      }
    }

    dns {
      servers = [var.nameserver]
    }

    user_account {
      keys     = [var.ssh_public_key]
      username = "ubuntu"
    }
  }

  agent {
    enabled = true
  }

  tags = ["k3s", "master"]
}

# --- K3s Workers ---

resource "proxmox_virtual_environment_vm" "k3s_workers" {
  count     = length(var.k3s_workers)
  node_name = var.pve_node
  vm_id     = var.k3s_workers[count.index].vmid
  name      = var.k3s_workers[count.index].name

  clone {
    vm_id = var.ci_template_vmid
    full  = true
  }

  cpu {
    cores = var.k3s_workers[count.index].cores
    type  = "host"
  }

  memory {
    dedicated = var.k3s_workers[count.index].memory
  }

  disk {
    datastore_id = var.storage
    interface    = "scsi0"
    size         = tonumber(replace(var.k3s_workers[count.index].disk, "G", ""))
  }

  network_device {
    bridge = var.bridge
  }

  initialization {
    datastore_id = "local"

    ip_config {
      ipv4 {
        address = var.k3s_workers[count.index].ip
        gateway = var.gateway
      }
    }

    dns {
      servers = [var.nameserver]
    }

    user_account {
      keys     = [var.ssh_public_key]
      username = "ubuntu"
    }
  }

  agent {
    enabled = true
  }

  tags = ["k3s", "worker"]
}
