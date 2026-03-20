output "k3s_master_ip" {
  description = "IP-адрес master-ноды"
  value       = var.k3s_master.ip
}

output "k3s_worker_ips" {
  description = "IP-адреса worker-нод"
  value       = [for w in var.k3s_workers : w.ip]
}
