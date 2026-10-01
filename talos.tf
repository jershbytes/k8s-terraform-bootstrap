# Generates cluster secrets/config, applies per-node machine configuration,
# bootstraps etcd, waits for health, and retrieves kubeconfig/talosconfig.

resource "talos_machine_secrets" "this" {
  talos_version = var.talos_version
}

data "talos_client_configuration" "this" {
  cluster_name         = var.cluster_name
  client_configuration = talos_machine_secrets.this.client_configuration
  nodes                = local.all_ips
  endpoints            = local.controlplane_ips
}

data "talos_machine_configuration" "controlplane" {
  cluster_name       = var.cluster_name
  machine_type       = "controlplane"
  cluster_endpoint   = "https://${var.control_plane_vip}:6443"
  machine_secrets    = talos_machine_secrets.this.machine_secrets
  talos_version      = var.talos_version
  kubernetes_version = var.kubernetes_version
}

data "talos_machine_configuration" "worker" {
  cluster_name       = var.cluster_name
  machine_type       = "worker"
  cluster_endpoint   = "https://${var.control_plane_vip}:6443"
  machine_secrets    = talos_machine_secrets.this.machine_secrets
  talos_version      = var.talos_version
  kubernetes_version = var.kubernetes_version
}

# Control plane nodes: static IP plus the Talos native virtual (shared) IP
# that floats across the three nodes and serves as the HA Kubernetes API
# endpoint - no kube-vip or external load balancer required.
resource "talos_machine_configuration_apply" "controlplane" {
  for_each = local.controlplane_nodes

  depends_on = [proxmox_virtual_environment_vm.node]

  client_configuration        = talos_machine_secrets.this.client_configuration
  machine_configuration_input = data.talos_machine_configuration.controlplane.machine_configuration
  node                        = each.value.ip
  apply_mode                  = "auto"

  config_patches = [
    yamlencode({
      machine = {
        network = {
          hostname = "talos-${each.key}"
          interfaces = [
            {
              deviceSelector = { physical = true }
              addresses      = ["${each.value.ip}/${var.network_prefix}"]
              routes = [
                { network = "0.0.0.0/0", gateway = var.network_gateway }
              ]
              vip = { ip = var.control_plane_vip }
            }
          ]
          nameservers = [var.network_gateway]
        }
      }
    })
  ]
}

resource "talos_machine_configuration_apply" "worker" {
  for_each = local.worker_nodes

  depends_on = [proxmox_virtual_environment_vm.node]

  client_configuration        = talos_machine_secrets.this.client_configuration
  machine_configuration_input = data.talos_machine_configuration.worker.machine_configuration
  node                        = each.value.ip
  apply_mode                  = "auto"

  config_patches = [
    yamlencode({
      machine = {
        network = {
          hostname = "talos-${each.key}"
          interfaces = [
            {
              deviceSelector = { physical = true }
              addresses      = ["${each.value.ip}/${var.network_prefix}"]
              routes = [
                { network = "0.0.0.0/0", gateway = var.network_gateway }
              ]
            }
          ]
          nameservers = [var.network_gateway]
        }
      }
    })
  ]
}

# Bootstraps etcd on the first control plane node and tracks the
# Kubernetes version for future `terraform apply`-driven upgrades.
resource "talos_cluster" "this" {
  depends_on = [
    talos_machine_configuration_apply.controlplane,
    talos_machine_configuration_apply.worker,
  ]

  client_configuration = talos_machine_secrets.this.client_configuration
  node                 = local.controlplane_ips[0]
  endpoint             = var.control_plane_vip
  control_plane_nodes  = local.controlplane_ips
  kubernetes_version   = var.kubernetes_version
}

data "talos_cluster_health" "this" {
  depends_on = [talos_cluster.this]

  client_configuration = talos_machine_secrets.this.client_configuration
  control_plane_nodes  = local.controlplane_ips
  worker_nodes         = local.worker_ips
  endpoints            = local.controlplane_ips
}

resource "talos_cluster_kubeconfig" "this" {
  depends_on = [data.talos_cluster_health.this]

  client_configuration = talos_machine_secrets.this.client_configuration
  node                 = local.controlplane_ips[0]
  endpoint             = var.control_plane_vip
}
