# Nutanix Virtual Machine Deployment — Terraform + Terragrunt

Infrastructure-as-Code deployment for managing Nutanix virtual machines using Terraform with Terragrunt orchestration. Supports **creating new VMs** and **importing existing VMs** into Terraform state.

---

## Directory Structure

```
tfm-nutanix/
├── Modules/                          # Reusable Terraform modules
│   ├── provider.tf                   # Nutanix provider + version constraints
│   ├── variables.tf                  # Shared provider credential variables
│   ├── virtual_machines/             # VM resource module
│   │   ├── variables.tf              # Complete VM variable schema (all v4 params)
│   │   ├── locals.tf                 # List → map transform, import/create split
│   │   ├── main.tf                   # nutanix_virtual_machine_v2 resource
│   │   ├── imports.tf                # Declarative import blocks
│   │   └── output.tf                 # VM IDs, names, attributes
│   ├── clusters/                     # Cluster name → ext_id lookup
│   │   ├── variables.tf
│   │   ├── main.tf
│   │   ├── locals.tf
│   │   └── output.tf
│   ├── networks/                     # Subnet name → ext_id lookup
│   │   ├── variables.tf
│   │   ├── main.tf
│   │   ├── locals.tf
│   │   └── output.tf
│   └── images/                       # Image name → ext_id lookup
│       ├── variables.tf
│       ├── main.tf
│       ├── locals.tf
│       └── output.tf
├── Config/                           # Reference YAML configs & standalone terragrunt
│   ├── terragrunt.hcl
│   ├── clusters.yaml
│   ├── networks.yaml
│   ├── images.yaml
│   └── virtual_machines.yaml         # Full examples with all parameter types
├── Deployments/                      # Per-cluster Terragrunt deployments
│   ├── terragrunt.hcl                # Root — backend, provider, shared inputs
│   └── cluster-01/                   # One directory per Nutanix cluster
│       ├── env.yaml                  # Cluster-specific overrides
│       ├── virtual_machines.yaml     # VM definitions for this cluster
│       ├── virtual_machines/         # Terragrunt entry point for VMs
│       │   └── terragrunt.hcl
│       ├── clusters/                 # Terragrunt entry point for cluster lookups
│       │   └── terragrunt.hcl
│       ├── networks/                 # Terragrunt entry point for network lookups
│       │   └── terragrunt.hcl
│       └── images/                   # Terragrunt entry point for image lookups
│           └── terragrunt.hcl
├── scripts/
│   ├── Import-ExistingVMs.ps1        # PowerShell import helper
│   └── import-existing-vms.sh        # Bash import helper
├── Makefile                          # Common operations
├── .gitignore
└── README.md
```

---

## Prerequisites

| Tool | Version | Purpose |
|------|---------|---------|
| **Terraform** | >= 1.5.0 | Required for declarative `import` blocks |
| **Terragrunt** | >= 0.50.0 | Orchestration, DRY config, remote state |
| **Nutanix Provider** | >= 2.0.0, < 3.0.0 | `nutanix_virtual_machine_v2` (v4 API) |
| **Prism Central** | >= pc.2022.6 | v4 API endpoint |

---

## Quick Start

### 1. Set Environment Variables

```bash
export NUTANIX_USERNAME="admin"
export NUTANIX_PASSWORD="your-password"
export NUTANIX_ENDPOINT="prism-central.example.com"

# State backend (S3)
export TG_STATE_BUCKET="nutanix-terraform-state"
export TG_STATE_REGION="us-east-1"
export TG_STATE_LOCK_TABLE="nutanix-terraform-locks"
```

### 2. Discover UUIDs (Optional)

Run the lookup modules to find cluster, subnet, and image UUIDs:

```bash
make clusters CLUSTER=cluster-01
make networks CLUSTER=cluster-01
make images   CLUSTER=cluster-01
```

### 3. Define VMs in YAML

Edit `Deployments/cluster-01/virtual_machines.yaml`:

```yaml
virtual_machines:
  # New VM
  - name: "my-new-vm"
    cluster:
      ext_id: "<cluster-uuid>"
    num_sockets: 2
    num_cores_per_socket: 2
    memory_size_bytes: 8589934592  # 8 GiB
    # ... (see Config/virtual_machines.yaml for all options)

  # Existing VM to import
  - name: "my-existing-vm"
    import_uuid: "<vm-uuid-from-prism>"
    cluster:
      ext_id: "<cluster-uuid>"
    num_sockets: 4
    # ... (values MUST match current VM state)
```

### 4. Deploy

```bash
# Initialize
make init CLUSTER=cluster-01

# Preview changes (imports + creates)
make plan CLUSTER=cluster-01

# Apply (imports existing VMs, creates new VMs)
make apply CLUSTER=cluster-01
```

---

## Importing Existing VMs

### Method 1: Declarative Import Blocks (Recommended)

Set `import_uuid` on VM entries in the YAML. The `imports.tf` module generates `import` blocks automatically. Just run:

```bash
make apply CLUSTER=cluster-01
```

Terraform will import the VMs and create/update them in one pass.

### Method 2: CLI Import (Fallback)

Use the helper scripts:

```bash
# Dry run — see what would be imported
make import-cli-dry CLUSTER=cluster-01

# Execute imports
make import-cli CLUSTER=cluster-01
```

### Method 3: Generate Config for Unknown VMs

If you don't know the exact parameters of an existing VM:

```bash
make generate-config CLUSTER=cluster-01
```

This generates `generated_imports.tf` with the actual state values — backport them into your YAML.

### Post-Import Workflow

1. Run `make plan` — if there's drift, the plan shows changes
2. Adjust YAML values to match reality until the plan is clean (no-op)
3. Remove `import_uuid` from the YAML — the VM stays in state
4. Now make intentional changes via YAML and re-apply

---

## Adding a New Cluster Environment

```bash
# Copy the cluster-01 template
cp -r Deployments/cluster-01 Deployments/cluster-02

# Edit env.yaml with cluster-02 specific settings
# Edit virtual_machines.yaml with cluster-02 VMs

# Deploy
make plan  CLUSTER=cluster-02
make apply CLUSTER=cluster-02
```

Each cluster gets its own isolated Terraform state file.

---

## Complete Parameter Reference

The VM variable schema in `Modules/virtual_machines/variables.tf` supports **every** parameter of the `nutanix_virtual_machine_v2` resource:

| Category | Parameters |
|----------|-----------|
| **Identity** | `name`, `description`, `import_uuid` |
| **Placement** | `cluster`, `host`, `availability_zone` |
| **CPU** | `num_sockets`, `num_cores_per_socket`, `num_threads_per_core`, `num_numa_nodes`, `is_vcpu_hard_pinning_enabled`, `is_cpu_passthrough_enabled`, `enabled_cpu_features`, `is_cpu_hotplug_enabled` |
| **Memory** | `memory_size_bytes`, `is_memory_overcommit_enabled` |
| **Boot** | `machine_type`, `boot_config` (legacy_boot / uefi_boot with secure boot & NVRAM) |
| **Disks** | `disks` (SCSI/IDE/PCI/SATA, image clone, VM disk clone, volume group, flash mode) |
| **CD-ROMs** | `cd_roms` (IDE/SATA with image backing) |
| **NICs** | `nics` (VIRTIO/E1000, static/DHCP IP, VLAN mode, network function chain) |
| **GPUs** | `gpus` (passthrough, virtual, vendor/mode/device_id) |
| **Serial** | `serial_ports` |
| **Guest Init** | `guest_customization` (cloud-init with user_data/metadata, Sysprep with unattend.xml) |
| **NGT** | `guest_tools` (is_enabled, capabilities) |
| **Storage** | `storage_config` (flash mode, QoS throttled IOPS) |
| **Security** | `vtpm_config`, `apc_config` |
| **Metadata** | `categories`, `project`, `ownership_info`, `protection_type` |
| **Other** | `power_state`, `source`, `hardware_clock_timezone`, `is_vga_console_enabled`, `is_gpu_console_enabled`, `is_branding_enabled`, `is_scsi_controller_enabled`, `is_agent_vm`, `generation_uuid`, `bios_uuid` |

See `Config/virtual_machines.yaml` for annotated examples of each.

---

## Credential Management

Provider credentials are sourced from environment variables:

| Env Var | Description | Default |
|---------|-------------|---------|
| `NUTANIX_USERNAME` | Prism Central username | (required) |
| `NUTANIX_PASSWORD` | Prism Central password | (required) |
| `NUTANIX_ENDPOINT` | Prism Central FQDN/IP | (required) |
| `NUTANIX_PORT` | API port | `9440` |
| `NUTANIX_INSECURE` | Skip SSL verification | `true` |
| `NUTANIX_SESSION_AUTH` | Use cookie-based auth | `true` |
| `NUTANIX_WAIT_TIMEOUT` | Operation timeout (min) | `10` |
| `NUTANIX_PROXY_URL` | HTTP proxy URL | (none) |

For production, consider integrating with HashiCorp Vault or a CI/CD secrets manager.
