### Proxmox connection ########################################################

variable "proxmox_api_url" {
  description = "Proxmox API endpoint, e.g. https://JTL-HME-PVE-01:8006/api2/json"
  type        = string
}

variable "proxmox_api_token" {
  description = "Proxmox API token in the form 'user@realm!token-id=uuid-secret'"
  type        = string
  sensitive   = true
}

variable "proxmox_insecure" {
  description = "Skip TLS certificate verification for the Proxmox API (not needed when using a trusted/Let's Encrypt cert)"
  type        = bool
  default     = true
}

### Source image ###############################################################

variable "talos_iso_file_id" {
  description = "Proxmox file ID of the Talos nocloud ISO (e.g. 'local:iso/nocloud-amd64.iso'), attached as each VM's CD-ROM for first boot"
  type        = string
  default     = "local:iso/nocloud-amd64.iso"
}

variable "proxmox_storage" {
  description = "Proxmox storage pool to place cloned VM disks on"
  type        = string
  default     = "zfs-storage"
}

variable "network_bridge" {
  description = "Proxmox network bridge to attach node NICs to"
  type        = string
  default     = "K8S"
}

### VM sizing ##################################################################

variable "vm_cpu_cores" {
  description = "Number of vCPU cores per node"
  type        = number
  default     = 4
}

variable "vm_memory_mb" {
  description = "Amount of RAM per node, in MB"
  type        = number
  default     = 16384
}

variable "vm_disk_gb" {
  description = "Disk size per node, in GB"
  type        = number
  default     = 100
}
