# Nutanix Virtual Machine Deployment — Terraform

Single-directory Terraform deployment for Nutanix virtual machines. Supply **names** for clusters, subnets, images, and storage containers — data sources automatically resolve them to UUIDs.

---

## Directory Structure

```
tfm-nutanix/
├── versions.tf              # Terraform & provider version constraints
├── provider.tf              # Nutanix provider configuration
├── variables.tf             # Provider vars + flat VM variable schema
├── data.tf                  # Data sources (clusters, subnets, images, storage containers)
├── locals.tf                # Name → ext_id lookup maps, VM transforms
├── main.tf                  # nutanix_virtual_machine_v2 resource
├── imports.tf               # Declarative import blocks for existing VMs
├── outputs.tf               # Lookup maps + VM outputs
├── terraform.tfvars.example # Example variable values — copy to terraform.tfvars
├── backend.tf.example       # Example remote state config
├── .gitignore
├── README.md
└── scripts/
    ├── Import-ExistingVMs.ps1   # PowerShell import helper (fallback)
    └── import-existing-vms.sh   # Bash import helper (fallback)
```

---

## Prerequisites

| Tool | Version | Purpose |
|------|---------|---------|
| **Terraform** | >= 1.5.0 | Required for declarative `import` blocks |
| **Nutanix Provider** | >= 2.0.0, < 3.0.0 | `nutanix_virtual_machine_v2` (v4 API) |
| **Prism Central** | >= pc.2022.6 | v4 API endpoint |

---

## Quick Start

### 1. Configure

```bash
cd tfm-nutanix/
cp terraform.tfvars.example terraform.tfvars
# Edit terraform.tfvars with your values
```

Or use environment variables for credentials:
```bash
export NUTANIX_USERNAME="admin"
export NUTANIX_PASSWORD="your-password"
export NUTANIX_ENDPOINT="prism-central.example.com"
```

### 2. Deploy

```bash
terraform init
terraform plan
terraform apply
```

That's it. Three commands.

---

## How Name Lookups Work

Instead of hunting for UUIDs, just use names:

```hcl
# OLD WAY — find and paste UUIDs everywhere
cluster = { ext_id = "00058ef4-c31d-6de0-0000-00000000b1f8" }
nics = [{ network_info = { subnet = { ext_id = "a3e4f8d2-..." } } }]
disks = [{ backing_info = { vm_disk = { storage_container = { ext_id = "..." }
  data_source = { reference = { image_reference = { image_ext_id = "..." } } } } } }]

# NEW WAY — just names
cluster_name = "Production-Cluster"
nics = [{ subnet_name = "VLAN-100-Production" }]
disks = [{ storage_container_name = "SSD-Container", image_name = "ubuntu-22.04" }]
```

The module queries Prism Central via data sources and builds name → ext_id maps automatically.

| You supply | Data source resolves |
|-----------|----------------------|
| `cluster_name` | `data.nutanix_clusters_v2` |
| `subnet_name` (in NICs) | `data.nutanix_subnets_v2` |
| `image_name` (in disks/CD-ROMs) | `data.nutanix_images_v2` |
| `storage_container_name` (in disks) | `data.nutanix_storage_containers_v2` |

> **Note:** Names must be unique within each resource type. If you have duplicate subnet names across clusters, rename them or extend the data source with filters.

---

## Defining VMs

Edit `terraform.tfvars`:

```hcl
virtual_machines = [
  {
    name                 = "web-server-01"
    cluster_name         = "Prod-Cluster"
    num_sockets          = 2
    num_cores_per_socket = 2
    memory_size_bytes    = 8589934592    # 8 GiB

    disks = [
      {
        storage_container_name = "SSD-Pool"
        image_name             = "ubuntu-22.04-server"
        disk_size_bytes        = 53687091200  # 50 GiB
      },
    ]

    nics = [
      {
        subnet_name      = "VLAN-100"
        should_assign_ip = true    # DHCP
      },
    ]
  },
]
```

See `terraform.tfvars.example` for complete examples including:
- Cloud-init guest customization
- Sysprep for Windows VMs
- UEFI Secure Boot
- Importing existing VMs

---

## Importing Existing VMs

### Method 1: Declarative Import (Recommended)

Add `import_uuid` to the VM definition:

```hcl
{
  name         = "legacy-db-01"
  import_uuid  = "AAAAAAAA-BBBB-CCCC-DDDD-EEEEEEEEEEEE"
  cluster_name = "Prod-Cluster"
  # ... values MUST match current VM state
}
```

Then just run:
```bash
terraform apply
```

Terraform imports the VM and reconciles state in one pass. After a clean plan, remove `import_uuid`.

### Method 2: CLI Import (Fallback)

```bash
# Dry run
./scripts/import-existing-vms.sh --dry-run

# Execute
./scripts/import-existing-vms.sh
```

### Post-Import Workflow

1. `terraform plan` — check for drift
2. Adjust tfvars values until the plan shows no changes
3. Remove `import_uuid` from tfvars
4. Now make intentional changes and re-apply

---

## Remote State

For shared/production use, copy `backend.tf.example` to `backend.tf` and configure your backend:

```bash
cp backend.tf.example backend.tf
# Edit backend.tf with your S3/GCS/Azure bucket details
terraform init -migrate-state
```

---

## All Supported Parameters

| Category | Parameters |
|----------|-----------|
| **Identity** | `name`, `description`, `import_uuid` |
| **Placement** | `cluster_name`, `host_ext_id`, `availability_zone_ext_id` |
| **CPU** | `num_sockets`, `num_cores_per_socket`, `num_threads_per_core`, `num_numa_nodes`, `is_vcpu_hard_pinning_enabled`, `is_cpu_passthrough_enabled`, `enabled_cpu_features`, `is_cpu_hotplug_enabled` |
| **Memory** | `memory_size_bytes`, `is_memory_overcommit_enabled` |
| **Boot** | `boot_config` (legacy/uefi, boot_order, secure boot, NVRAM) |
| **Disks** | `disks[]` — `bus_type`, `index`, `disk_size_bytes`, `storage_container_name`, `image_name`, `clone_from_vm_disk`, `volume_group_ext_id`, `is_flash_mode_enabled` |
| **CD-ROMs** | `cd_roms[]` — `bus_type`, `index`, `image_name` |
| **NICs** | `nics[]` — `subnet_name`, `model`, `ip_address`, `should_assign_ip`, `nic_type`, `vlan_mode`, `mac_address`, `secondary_ips` |
| **GPUs** | `gpus[]` — `vendor`, `mode`, `device_id` |
| **Serial** | `serial_ports[]` — `index`, `is_connected` |
| **Guest Init** | `guest_customization` — `type` (cloud_init/sysprep), user_data, unattend_xml, custom_keys |
| **NGT** | `guest_tools` — `is_enabled`, `capabilities` |
| **Storage** | `storage_config` — `is_flash_mode_enabled`, `throttled_iops` |
| **Security** | `vtpm_config`, `apc_config` |
| **Metadata** | `categories`, `project_ext_id`, `owner_ext_id`, `protection_type` |
| **Other** | `power_state`, `machine_type`, `source_entity_type`, `hardware_clock_timezone`, console flags, BIOS/generation UUID |

---

## Credential Management

| Method | Variable | Env Var |
|--------|----------|---------|
| Username | `nutanix_username` | `NUTANIX_USERNAME` |
| Password | `nutanix_password` | `NUTANIX_PASSWORD` |
| Endpoint | `nutanix_endpoint` | `NUTANIX_ENDPOINT` |
| Port | `nutanix_port` | `NUTANIX_PORT` (default: 9440) |
| Skip TLS | `nutanix_insecure` | `NUTANIX_INSECURE` (default: true) |
| Session Auth | `nutanix_session_auth` | `NUTANIX_SESSION_AUTH` (default: true) |
| Timeout | `nutanix_wait_timeout` | `NUTANIX_WAIT_TIMEOUT` (default: 10) |
| Proxy | `nutanix_proxy_url` | `NUTANIX_PROXY_URL` |

---

## Useful Commands

```bash
terraform init                       # Initialize providers
terraform plan                       # Preview changes
terraform apply                      # Apply changes
terraform output cluster_map         # See discovered cluster names → UUIDs
terraform output subnet_map          # See discovered subnet names → UUIDs
terraform output image_map           # See discovered image names → UUIDs
terraform output storage_container_map  # See discovered container names → UUIDs
terraform output vm_ids              # See deployed VM names → UUIDs
terraform state list                 # List all managed resources
terraform plan -generate-config-out=generated_imports.tf  # Generate config for imported VMs
```
