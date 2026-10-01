# List available commands.
default:
  @just --list

# Format Terraform/OpenTofu files recursively.
fmt:
  tofu fmt -recursive

# Validate the configuration after initialization.
validate:
  tofu validate

# Initialize the OpenTofu working directory and providers.
init:
  tofu init

# Show the proposed infrastructure changes.
plan:
  tofu plan

# Apply the configuration without an interactive approval prompt.
apply:
  tofu apply --auto-approve

# Fetch credentials, check Talos health, and list K8s nodes.
grab-creds:
  #!/bin/bash
  set -euo pipefail
  umask 077

  tofu output -raw talosconfig > talosconfig
  tofu output -raw kubeconfig > kubeconfig
  chmod 600 talosconfig kubeconfig

  export TALOSCONFIG="$PWD/talosconfig"
  export KUBECONFIG="$PWD/kubeconfig"

  talosctl health --nodes 172.42.1.10,172.42.1.11,172.42.1.12
  kubectl get nodes -o wide