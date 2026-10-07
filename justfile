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

