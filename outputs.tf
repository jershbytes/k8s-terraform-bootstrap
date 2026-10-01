output "control_plane_vip" {
  description = "Shared virtual IP serving as the Kubernetes API endpoint"
  value       = var.control_plane_vip
}

output "node_ips" {
  description = "Static IP address assigned to each node"
  value       = { for k, v in local.nodes : k => v.ip }
}

output "node_macs" {
  description = "MAC address assigned to each node's NIC - use these to create matching DHCP static reservations"
  value       = { for k, v in local.nodes : k => v.mac_address }
}

output "talosconfig" {
  description = "Talos client configuration (talosconfig). Save with: terraform output -raw talosconfig > talosconfig"
  value       = data.talos_client_configuration.this.talos_config
  sensitive   = true
}

output "kubeconfig" {
  description = "Kubernetes client configuration. Save with: terraform output -raw kubeconfig > kubeconfig"
  value       = talos_cluster_kubeconfig.this.kubeconfig_raw
  sensitive   = true
}
