# Creates 5 VMs spread across the 3-node Proxmox cluster. They boot from the
# Talos nocloud ISO and stay in maintenance mode; cluster configuration is
# handled separately.
resource "proxmox_virtual_environment_vm" "node" {
  for_each = local.nodes

  name      = "talos-${each.key}"
  node_name = each.value.target_node
  vm_id     = each.value.vm_id
  tags      = ["talos", each.value.role, "terraform"]

  # The schematic backing the ISO has the qemu-guest-agent system extension
  # baked in, which tries to start at boot and waits indefinitely for
  # Proxmox to expose the virtio-serial guest-agent channel. If this is left
  # disabled, that service never comes up and the node's boot sequence never
  # reports complete (stuck at STAGE: Booting). Keep this enabled to match
  # the extension.
  agent {
    enabled = true
  }

  started         = true
  stop_on_destroy = true

  # Use UEFI without pre-enrolled Secure Boot keys. The vTPM is retained for
  # compatibility with existing VMs, but Secure Boot is not enabled.
  bios    = "ovmf"
  machine = "q35"

  efi_disk {
    datastore_id      = var.proxmox_storage
    type              = "4m"
    pre_enrolled_keys = false
  }

  tpm_state {
    datastore_id = var.proxmox_storage
    version      = "v2.0"
  }

  cpu {
    cores = var.vm_cpu_cores
    type  = "host"
  }

  memory {
    dedicated = var.vm_memory_mb
  }

  # Keep a blank boot disk so the VM falls through to the ISO into maintenance
  # mode on every start until cluster configuration is applied elsewhere.
  disk {
    datastore_id = var.proxmox_storage
    interface    = "scsi0"
    size         = var.vm_disk_gb
  }

  cdrom {
    file_id   = var.talos_iso_file_id
    interface = "ide2"
  }

  boot_order = ["scsi0", "ide2"]

  network_device {
    bridge      = var.network_bridge
    mac_address = each.value.mac_address
  }

  operating_system {
    type = "l26"
  }
}
