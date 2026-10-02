# Talos Linux VMs on Proxmox

Creates and starts five Talos Linux VMs across a three-node Proxmox cluster.
Each VM boots from a standard Talos `nocloud-amd64.iso` into **maintenance
mode** and remains there. This repository does not configure Talos, bootstrap
Kubernetes, create an API endpoint, or retrieve cluster credentials. Set up
and cluster the nodes separately in [k8s-home-ops](https://github.com/jershbytes/k8s-home-ops).

The only API Terraform uses is the **Proxmox API** to create and start VMs.
No Kubernetes API endpoint or Talos API credentials are needed for this step.

## Topology

| Node     | Intended role | Proxmox host   | DHCP-reserved IP | MAC address       |
| -------- | ------------- | -------------- | ---------------- | ----------------- |
| cp-1     | control plane | JTL-HME-PVE-01  | 172.42.1.10      | BC:24:11:00:10:01 |
| cp-2     | control plane | JTL-HME-PVE-02  | 172.42.1.11      | BC:24:11:00:10:02 |
| cp-3     | control plane | JTL-HME-PVE-03  | 172.42.1.12      | BC:24:11:00:10:03 |
| worker-1 | worker        | JTL-HME-PVE-01  | 172.42.1.13      | BC:24:11:00:10:04 |
| worker-2 | worker        | JTL-HME-PVE-02  | 172.42.1.14      | BC:24:11:00:10:05 |

The addresses above are DHCP reservation suggestions, not static addresses
configured in Talos. Reserve the listed MAC-to-IP pairs on the DHCP server
for the network connected to the `K8S` bridge so the maintenance-mode nodes
have predictable addresses. Change the node definitions in [locals.tf](./locals.tf)
to match your environment.

## Prerequisites

1. Upload the standard Talos `nocloud-amd64.iso` to Proxmox storage that
   supports ISO content and note its Proxmox file ID, such as
   `local:iso/nocloud-amd64.iso`.
2. Create a Proxmox API token for Terraform with permissions to create,
   configure, audit, and power-manage VMs and allocate storage.
3. Install OpenTofu >= 1.8 and [`just`](https://just.systems/man/en/).
4. Reserve the node MAC/IP pairs shown above in DHCP.

## Usage

```sh
cp terraform.tfvars.example terraform.tfvars
# Edit terraform.tfvars with your Proxmox API URL and token,
# ISO file ID, storage pool, and network bridge.

just init
just plan
just apply
```

After apply, all five VMs are running the Talos ISO in maintenance mode.
Check their DHCP leases or use the reservation list to reach them. The
cluster configuration and Kubernetes API endpoint are intentionally left to
the separate `k8s-home-ops` workflow.

## Notes

- Each VM has a blank `scsi0` disk and boots from the Talos ISO. Since no
  configuration is applied here, the node stays in maintenance mode and does
  not install Talos onto that disk.
- The `qemu-guest-agent` extension on the ISO requires the VM agent channel,
  so the Proxmox guest agent setting remains enabled.
- `cpu.type = "host"` requires compatible CPUs across all three Proxmox hosts.
- Adjust VM sizing, placement, and node addresses in [locals.tf](./locals.tf)
  and [variables.tf](./variables.tf).

## File layout

| File                      | Purpose                                        |
| ------------------------- | ---------------------------------------------- |
| `versions.tf`             | Terraform/provider version constraints        |
| `providers.tf`             | Proxmox provider configuration                 |
| `variables.tf`             | Proxmox, ISO, storage, and VM sizing inputs   |
| `locals.tf`                | Per-node placement and DHCP reservation details |
| `vms.tf`                   | Proxmox VM creation and Talos ISO boot         |
| `outputs.tf`               | Node IP and MAC address maps                   |
| `terraform.tfvars.example` | Template for local `terraform.tfvars`          |
