# Per-node VM placement and DHCP reservation details.
#
# Nodes remain in Talos maintenance mode and obtain their addresses from
# DHCP. Reserve each MAC-to-IP pair on your DHCP server for stable access.
locals {
  nodes = {
    cp-1 = {
      role        = "controlplane"
      vm_id       = 401
      target_node = "JTL-HME-PVE-01"
      ip          = "172.42.1.10"
      mac_address = "bc:24:11:00:10:01"
    }
    cp-2 = {
      role        = "controlplane"
      vm_id       = 402
      target_node = "JTL-HME-PVE-02"
      ip          = "172.42.1.11"
      mac_address = "bc:24:11:00:10:02"
    }
    cp-3 = {
      role        = "controlplane"
      vm_id       = 403
      target_node = "JTL-HME-PVE-03"
      ip          = "172.42.1.12"
      mac_address = "bc:24:11:00:10:03"
    }
    worker-1 = {
      role        = "worker"
      vm_id       = 404
      target_node = "JTL-HME-PVE-01"
      ip          = "172.42.1.13"
      mac_address = "bc:24:11:00:10:04"
    }
    worker-2 = {
      role        = "worker"
      vm_id       = 405
      target_node = "JTL-HME-PVE-02"
      ip          = "172.42.1.14"
      mac_address = "bc:24:11:00:10:05"
    }
  }

}
