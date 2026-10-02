output "node_ips" {
  description = "Expected DHCP-reserved IP address for each node while it is in Talos maintenance mode"
  value       = { for k, v in local.nodes : k => v.ip }
}

output "node_macs" {
  description = "MAC address assigned to each node's NIC; pair with node_ips to create DHCP reservations"
  value       = { for k, v in local.nodes : k => v.mac_address }
}
