# Static per-node definitions: role, placement, VM ID, IP, and MAC address.
#
# MAC addresses are pinned so you can create matching DHCP static
# reservations in your router/firewall for the K8S bridge. Talos nodes boot
# into maintenance mode using DHCP; by reserving the same address that is
# also baked into each node's static machine config below, the node never
# changes IP between first boot and the final configured state.
locals {
  nodes = {
    cp-1 = {
      role        = "controlplane"
      vm_id       = 9201
      target_node = "JTL-HME-PVE-01"
      ip          = "172.42.1.10"
      mac_address = "BC:24:11:00:10:01"
    }
    cp-2 = {
      role        = "controlplane"
      vm_id       = 9202
      target_node = "JTL-HME-PVE-02"
      ip          = "172.42.1.11"
      mac_address = "BC:24:11:00:10:02"
    }
    cp-3 = {
      role        = "controlplane"
      vm_id       = 9203
      target_node = "JTL-HME-PVE-03"
      ip          = "172.42.1.12"
      mac_address = "BC:24:11:00:10:03"
    }
    worker-1 = {
      role        = "worker"
      vm_id       = 9204
      target_node = "JTL-HME-PVE-01"
      ip          = "172.42.1.13"
      mac_address = "BC:24:11:00:10:04"
    }
    worker-2 = {
      role        = "worker"
      vm_id       = 9205
      target_node = "JTL-HME-PVE-02"
      ip          = "172.42.1.14"
      mac_address = "BC:24:11:00:10:05"
    }
  }

  controlplane_nodes = { for k, v in local.nodes : k => v if v.role == "controlplane" }
  worker_nodes       = { for k, v in local.nodes : k => v if v.role == "worker" }

  controlplane_ips = [for v in local.controlplane_nodes : v.ip]
  worker_ips       = [for v in local.worker_nodes : v.ip]
  all_ips          = [for v in local.nodes : v.ip]
}
