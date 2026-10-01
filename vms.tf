# Clones the existing Talos template into 5 VMs spread across the 3-node
# Proxmox cluster. Talos itself is configured later via the talos provider
# (see talos.tf) - these resources only handle VM placement/sizing.
resource "proxmox_virtual_environment_vm" "node" {
  for_each = local.nodes

  name      = "talos-${each.key}"
  node_name = each.value.target_node
  vm_id     = each.value.vm_id
  tags      = ["talos", each.value.role, "terraform"]

  # Talos has no cloud-init/agent support in the traditional sense until
  # explicitly enabled via the qemu-guest-agent system extension, so leave
  # the agent disabled unless your template was built with that extension.
  agent {
    enabled = false
  }

  stop_on_destroy = true

  clone {
    vm_id     = var.talos_template_vm_id
    node_name = var.talos_template_node
    full      = true
  }

  cpu {
    cores = var.vm_cpu_cores
    type  = "host"
  }

  memory {
    dedicated = var.vm_memory_mb
  }

  disk {
    datastore_id = var.proxmox_storage
    interface    = "scsi0"
    size         = var.vm_disk_gb
  }

  network_device {
    bridge      = var.network_bridge
    mac_address = each.value.mac_address
  }

  operating_system {
    type = "l26"
  }

  lifecycle {
    ignore_changes = [
      clone,
    ]
  }
}
