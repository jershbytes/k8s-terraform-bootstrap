# Clones the existing Talos template into 5 VMs spread across the 3-node
# Proxmox cluster. Talos itself is configured later via the talos provider
# (see talos.tf) - these resources only handle VM placement/sizing.
resource "proxmox_virtual_environment_vm" "node" {
  for_each = local.nodes

  name      = "talos-${each.key}"
  node_name = each.value.target_node
  vm_id     = each.value.vm_id
  tags      = ["talos", each.value.role, "terraform"]

  # The Talos template has the qemu-guest-agent system extension baked in,
  # which tries to start at boot and waits indefinitely for Proxmox to
  # expose the virtio-serial guest-agent channel. If this is left disabled,
  # that service never comes up, the node's boot sequence never reports
  # complete (stuck at STAGE: Booting), and talos_cluster never passes its
  # health checks. Must stay enabled to match the extension in the image.
  agent {
    enabled = true
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
