# Creates 5 VMs spread across the 3-node Proxmox cluster, each booting from
# the Talos nocloud secure boot ISO on first start. Talos itself is
# configured later via the talos provider (see talos.tf): the ISO brings the
# node up in maintenance mode, Terraform applies a machine config whose
# install.image points at the matching Image Factory installer-secureboot
# image, and Talos installs itself onto the blank scsi0 disk and reboots.
resource "proxmox_virtual_environment_vm" "node" {
  for_each = local.nodes

  name      = "talos-${each.key}"
  node_name = each.value.target_node
  vm_id     = each.value.vm_id
  tags      = ["talos", each.value.role, "terraform"]

  # The schematic backing the ISO has the qemu-guest-agent system extension
  # baked in, which tries to start at boot and waits indefinitely for
  # Proxmox to expose the virtio-serial guest-agent channel. If this is left
  # disabled, that service never comes up, the node's boot sequence never
  # reports complete (stuck at STAGE: Booting), and talos_cluster never
  # passes its health checks. Must stay enabled to match the extension.
  agent {
    enabled = true
  }

  stop_on_destroy = true

  # Secure Boot requires OVMF (UEFI) firmware plus a q35 machine type, an EFI
  # disk to persist the UEFI variables/Secure Boot state (with Microsoft's
  # standard keys pre-enrolled, matching the signed Talos secureboot image),
  # and a vTPM for measured boot.
  bios    = "ovmf"
  machine = "q35"

  efi_disk {
    datastore_id      = var.proxmox_storage
    type              = "4m"
    pre_enrolled_keys = true
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

  # Blank boot disk: Talos installs itself here once the machine config is
  # applied. Boot order tries this first - it has no bootloader until Talos
  # installs onto it, so UEFI falls through to the CD-ROM automatically on
  # first boot, then boots straight from disk on every boot after that.
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
