# Talos Linux on Proxmox - Terraform Bootstrap

Bootstraps a 5-node Talos Linux Kubernetes cluster (3 control plane, 2 worker)
on a 3-node Proxmox cluster, cloning an existing Talos template.

Terraform handles the entire flow in one `apply`:

1. **`bpg/proxmox`** provider clones the template into 5 VMs, spread
   round-robin across your 3 Proxmox nodes.
2. **`siderolabs/talos`** provider generates machine configs, applies them,
   bootstraps etcd, waits for cluster health, and retrieves
   `kubeconfig`/`talosconfig`.

Ansible is intentionally not used: Talos has no SSH/shell/package manager and
is designed to be configured declaratively through its own API, which the
Talos Terraform provider speaks natively.

## Topology

| Node     | Role          | Proxmox host     | IP            |
| -------- | ------------- | ----------------- | ------------- |
| cp-1     | control plane | JTL-HME-PVE-01     | 172.42.1.10   |
| cp-2     | control plane | JTL-HME-PVE-02     | 172.42.1.11   |
| cp-3     | control plane | JTL-HME-PVE-03     | 172.42.1.12   |
| worker-1 | worker        | JTL-HME-PVE-01     | 172.42.1.13   |
| worker-2 | worker        | JTL-HME-PVE-02     | 172.42.1.14   |

The Kubernetes API endpoint is `https://172.42.1.9:6443` - a **Talos native
virtual (shared) IP** that floats across the three control plane nodes via
layer-2 ARP/etcd leader election. This achieves the same HA goal as
kube-vip without deploying any extra pod/manifest, since Talos supports it
natively (`machine.network.interfaces[].vip`).

Edit [locals.tf](./locals.tf) if you want different IPs, VM IDs, placement,
or to add more nodes. Your `/28` network (172.42.1.0/28) has 13 usable
addresses; 6 are used (5 nodes + VIP), leaving room for a couple more nodes
before you'd need to expand the subnet.

## Prerequisites

### 1. Proxmox API token

Create a dedicated API token for Terraform (Datacenter -> Permissions ->
API Tokens), and grant it a role with at least:

`VM.Allocate, VM.Clone, VM.Config.Disk, VM.Config.CPU, VM.Config.Memory, VM.Config.Network, VM.Config.Options, VM.Audit, VM.PowerMgmt, Datastore.AllocateSpace, Datastore.Audit, Sys.Audit`

The built-in `PVEVMAdmin` + `PVEDatastoreUser` roles cover this if you'd
rather not build a custom role. **Uncheck "Privilege Separation"** on the
token, or explicitly grant the role to the token itself (not just the user).

### 2. DHCP static reservations

Each VM's NIC is pinned to a specific MAC address in [locals.tf](./locals.tf)
so you can reserve the **same IP** for that MAC on your router/DHCP server
ahead of time. This matters because:

- On first boot (before any Talos config exists), a cloned VM boots into
  Talos "maintenance mode" and requests an address over DHCP.
- Terraform then applies a machine config that sets that same address as a
  **static** IP on the node.

Because the DHCP-assigned address and the final static address are
identical, the node never changes IP mid-bootstrap, and Terraform can talk
to each node's final IP from the very first `apply`. Run
`terraform output node_macs` after a plan to see the MAC -> IP pairs to
reserve.

### 3. Tooling

- [Terraform](https://developer.hashicorp.com/terraform/downloads) >= 1.8
- [`talosctl`](https://www.talos.dev/latest/talos-guides/install/talosctl/) and
  [`kubectl`](https://kubernetes.io/docs/tasks/tools/) for day-2 operations

## Usage

```sh
cp terraform.tfvars.example terraform.tfvars
# edit terraform.tfvars with your Proxmox API token, etc.

terraform init
terraform plan
terraform apply
```
 [OpenTofu](https://opentofu.org/docs/intro/install/) >= 1.8
 [`just`](https://just.systems/man/en/) for the project command recipes
This takes several minutes: cloning 5 VMs, waiting for maintenance-mode
boot, applying config, bootstrapping etcd, and waiting for full cluster
health (Talos + Kubernetes).

Once `apply` completes, pull down your credentials:

```sh
just init
just plan
just apply
export TALOSCONFIG=$(pwd)/talosconfig
export KUBECONFIG=$(pwd)/kubeconfig

talosctl health --nodes 172.42.1.10,172.42.1.11,172.42.1.12
kubectl get nodes -o wide
just grab-creds
  (the default for a single `scsi0` disk). Add a `machine.install.disk`
  config patch in [talos.tf](./talos.tf) if your template uses a different
  device.
- **CPU type**: `cpu.type = "host"` requires all 3 Proxmox hosts to have
  compatible CPUs (or live migration/consistent features aren't guaranteed).
  Change to a baseline model (e.g. `x86-64-v2-AES`) if your 3 nodes have
  different CPU generations.
- **Scaling up**: to add more workers, add an entry to `local.nodes` in
  [locals.tf](./locals.tf) (and a free IP in-subnet), then `terraform apply`.
- **Upgrades**: bump `kubernetes_version` in `terraform.tfvars` to drive a
  rolling Kubernetes upgrade via the `talos_cluster` resource. Talos OS
  upgrades are handled separately (typically via `talosctl upgrade` or by
  patching `machine.install.image`).

## File layout
  [locals.tf](./locals.tf) (and a free IP in-subnet), then `tofu apply`.
| File                        | Purpose                                               |
| --------------------------- | ------------------------------------------------------ |
| `versions.tf`                | Terraform/provider version constraints                |
| `providers.tf`               | Proxmox + Talos provider configuration                 |
| `variables.tf`               | Input variables                                        |
| `locals.tf`                  | Per-node topology (IPs, MACs, VM IDs, placement)       |
| `vms.tf`                     | Proxmox VM cloning                                     |
| `talos.tf`                   | Talos machine config generation, apply, bootstrap      |
| `outputs.tf`                 | `kubeconfig`, `talosconfig`, node IP/MAC outputs       |
| `terraform.tfvars.example`   | Template for your local `terraform.tfvars`             |
