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

### Source template ###########################################################

variable "talos_template_vm_id" {
  description = "VM ID of the existing Talos template to clone"
  type        = number
  default     = 912
}

variable "talos_template_node" {
  description = "Proxmox node name where the Talos template currently lives"
  type        = string
  default     = "JTL-HME-PVE-03"
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

### Cluster networking #########################################################

variable "network_prefix" {
  description = "CIDR prefix length for the cluster network"
  type        = number
  default     = 28
}

variable "network_gateway" {
  description = "Gateway/DNS address for the cluster network"
  type        = string
  default     = "172.42.1.1"
}

variable "control_plane_vip" {
  description = "Shared virtual IP (Talos native VIP) used as the Kubernetes API endpoint across control plane nodes"
  type        = string
  default     = "172.42.1.9"
}

### Talos / Kubernetes versions ################################################

variable "cluster_name" {
  description = "Name of the Talos/Kubernetes cluster"
  type        = string
  default     = "homelab"
}

variable "talos_version" {
  description = "Talos version contract used to generate machine configuration"
  type        = string
  default     = "v1.14"
}

variable "kubernetes_version" {
  description = "Kubernetes version to bootstrap the cluster with"
  type        = string
  default     = "v1.37.1"
}
