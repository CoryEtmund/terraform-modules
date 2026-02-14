###############################################################################
# Variables — Provider & Virtual Machine Definitions
#
# The VM schema is intentionally FLAT.  Instead of deeply nested objects with
# ext_ids, you supply human-readable names (cluster_name, subnet_name,
# image_name, storage_container_name) and the module resolves them to ext_ids
# via data source lookups.
###############################################################################

# =============================================================================
# Provider Credentials
# =============================================================================

variable "nutanix_username" {
  description = "Username for Nutanix Prism Central API."
  type        = string
  default     = null
}

variable "nutanix_password" {
  description = "Password for Nutanix Prism Central API."
  type        = string
  sensitive   = true
  default     = null
}

variable "nutanix_endpoint" {
  description = "Nutanix Prism Central IP address or FQDN."
  type        = string
  default     = null
}

variable "nutanix_port" {
  description = "Port for Nutanix Prism Central API."
  type        = number
  default     = 9440
}

variable "nutanix_insecure" {
  description = "Whether to skip SSL certificate verification."
  type        = bool
  default     = true
}

variable "nutanix_session_auth" {
  description = "Use session-based authentication."
  type        = bool
  default     = true
}

variable "nutanix_wait_timeout" {
  description = "Timeout in minutes for resource operations."
  type        = number
  default     = 10
}

variable "nutanix_proxy_url" {
  description = "Proxy URL for Nutanix Prism Central."
  type        = string
  default     = null
}

# =============================================================================
# Virtual Machines
# =============================================================================

variable "virtual_machines" {
  description = <<-EOT
    List of virtual machine definitions.  Each entry creates (or imports) one
    nutanix_virtual_machine_v2 resource.

    Name-based lookups (resolved automatically via data sources):
      - cluster_name           → cluster ext_id
      - nics[].subnet_name     → subnet ext_id
      - disks[].image_name     → image ext_id
      - disks[].storage_container_name → storage container ext_id
  EOT

  type = list(object({

    # =========================================================================
    # Identity & Import
    # =========================================================================
    name        = string                 # (Required) VM display name — must be unique
    description = optional(string, null) # VM description
    import_uuid = optional(string, null) # Set to existing VM UUID to import; remove after first apply

    # =========================================================================
    # Placement (name-based lookup)
    # =========================================================================
    cluster_name = string # (Required) Nutanix cluster name — looked up automatically

    # Placement (ext_id overrides for advanced use)
    host_ext_id              = optional(string, null) # Pin to a specific host
    availability_zone_ext_id = optional(string, null) # AZ placement

    # =========================================================================
    # Compute — CPU
    # =========================================================================
    num_sockets          = number                          # (Required) CPU sockets
    num_cores_per_socket = optional(number, 1)             # Cores per socket
    num_threads_per_core = optional(number, 1)             # Threads per core (SMT)
    num_numa_nodes       = optional(number, 0)             # vNUMA nodes; 0 = disabled
    power_state          = optional(string, "ON")          # ON or OFF

    is_vcpu_hard_pinning_enabled = optional(bool, null)
    is_cpu_passthrough_enabled   = optional(bool, null)
    enabled_cpu_features         = optional(list(string), null) # e.g. ["HARDWARE_VIRTUALIZATION"]
    is_cpu_hotplug_enabled       = optional(bool, null)

    # =========================================================================
    # Compute — Memory
    # =========================================================================
    memory_size_bytes            = number                # (Required) Memory in bytes
    is_memory_overcommit_enabled = optional(bool, null)

    # =========================================================================
    # Machine Type & Boot
    # =========================================================================
    machine_type = optional(string, null) # PC, Q35, or PSERIES

    boot_config = optional(object({
      boot_type = optional(string, "legacy") # "legacy" or "uefi"

      # Legacy boot options
      boot_order         = optional(list(string), null) # e.g. ["DISK", "CDROM", "NETWORK"]
      boot_disk_bus_type = optional(string, null)       # Specific boot disk bus type
      boot_disk_index    = optional(number, null)       # Specific boot disk index
      boot_nic_mac       = optional(string, null)       # Boot from NIC by MAC

      # UEFI boot options
      is_secure_boot_enabled       = optional(bool, false)
      nvram_disk_size_bytes        = optional(number, null)
      nvram_storage_container_name = optional(string, null) # Name-based lookup
      nvram_image_name             = optional(string, null) # Name-based lookup
    }), null)

    # =========================================================================
    # Disks (simplified flat schema)
    # =========================================================================
    disks = optional(list(object({
      bus_type               = optional(string, "SCSI") # SCSI, IDE, PCI, SATA, SPAPR
      index                  = optional(number, null)
      disk_size_bytes        = optional(number, null)
      storage_container_name = optional(string, null) # Name-based lookup
      image_name             = optional(string, null) # Name-based lookup (clone from image)
      is_flash_mode_enabled  = optional(bool, null)

      # Advanced: clone from another VM's disk
      clone_from_vm_disk = optional(object({
        disk_ext_id = string
        vm_ext_id   = optional(string, null)
        bus_type    = optional(string, null)
        index       = optional(number, null)
      }), null)

      # Advanced: attach a volume group
      volume_group_ext_id = optional(string, null)
    })), [])

    # =========================================================================
    # CD-ROMs (simplified flat schema)
    # =========================================================================
    cd_roms = optional(list(object({
      bus_type    = optional(string, "IDE") # IDE or SATA
      index       = optional(number, null)
      image_name  = optional(string, null)  # Name-based lookup (ISO image)
    })), [])

    # =========================================================================
    # NICs (simplified flat schema)
    # =========================================================================
    nics = optional(list(object({
      subnet_name      = string                            # (Required) Subnet name — looked up automatically
      model            = optional(string, null)            # VIRTIO or E1000
      is_connected     = optional(bool, true)
      mac_address      = optional(string, null)
      nic_type         = optional(string, "NORMAL_NIC")    # NORMAL_NIC, DIRECT_NIC, NETWORK_FUNCTION_NIC
      vlan_mode        = optional(string, null)            # ACCESS or TRUNK
      should_assign_ip = optional(bool, null)              # true = DHCP/IPAM
      ip_address       = optional(string, null)            # Static IP
      prefix_length    = optional(number, null)
      num_queues       = optional(number, null)

      secondary_ips = optional(list(object({
        value         = string
        prefix_length = optional(number, null)
      })), null)

      # Advanced
      network_function_chain_ext_id = optional(string, null)
      network_function_nic_type     = optional(string, null) # INGRESS, EGRESS, TAP
    })), [])

    # =========================================================================
    # GPUs
    # =========================================================================
    gpus = optional(list(object({
      vendor    = optional(string, null) # NVIDIA, AMD, INTEL
      mode      = optional(string, null) # PASSTHROUGH_GRAPHICS, PASSTHROUGH_COMPUTE, VIRTUAL
      device_id = optional(number, null)
    })), [])

    # =========================================================================
    # Serial Ports
    # =========================================================================
    serial_ports = optional(list(object({
      index        = number
      is_connected = optional(bool, true)
    })), [])

    # =========================================================================
    # Guest Customization (flat — pick type, fill relevant fields)
    # =========================================================================
    guest_customization = optional(object({
      type = string # "cloud_init" or "sysprep"

      # Cloud-init fields
      cloud_init_datasource  = optional(string, "CONFIG_DRIVE_V2") # CONFIG_DRIVE_V2
      cloud_init_metadata    = optional(string, null)              # Base64-encoded
      cloud_init_user_data   = optional(string, null)              # Base64-encoded
      cloud_init_custom_keys = optional(list(object({
        name  = string
        value = string
      })), null)

      # Sysprep fields
      sysprep_install_type = optional(string, "PREPARED") # PREPARED or FRESH
      sysprep_unattend_xml = optional(string, null)       # Base64-encoded unattend.xml
      sysprep_custom_keys  = optional(list(object({
        name  = string
        value = string
      })), null)
    }), null)

    # =========================================================================
    # Guest Tools (NGT)
    # =========================================================================
    guest_tools = optional(object({
      is_enabled   = optional(bool, null)
      capabilities = optional(list(string), null) # ["SELF_SERVICE_RESTORE", "VSS_SNAPSHOT"]
    }), null)

    # =========================================================================
    # Storage Configuration
    # =========================================================================
    storage_config = optional(object({
      is_flash_mode_enabled = optional(bool, null)
      throttled_iops        = optional(number, null)
    }), null)

    # =========================================================================
    # Security — vTPM
    # =========================================================================
    vtpm_config = optional(object({
      is_vtpm_enabled = optional(bool, false)
      version         = optional(string, null)
    }), null)

    # =========================================================================
    # Advanced Processor Compatibility (APC)
    # =========================================================================
    apc_config = optional(object({
      is_apc_enabled   = optional(bool, false)
      cpu_model_ext_id = optional(string, null)
    }), null)

    # =========================================================================
    # Categories, Project & Ownership (ext_id based)
    # =========================================================================
    categories     = optional(list(object({ ext_id = string })), null)
    project_ext_id = optional(string, null)
    owner_ext_id   = optional(string, null)

    # =========================================================================
    # Protection
    # =========================================================================
    protection_type = optional(string, null) # UNPROTECTED, PD_PROTECTED, RULE_PROTECTED

    # =========================================================================
    # Miscellaneous
    # =========================================================================
    source_entity_type         = optional(string, null)  # VM or VM_RECOVERY_POINT
    hardware_clock_timezone    = optional(string, null)   # IANA timezone
    is_vga_console_enabled     = optional(bool, null)
    is_gpu_console_enabled     = optional(bool, null)
    is_branding_enabled        = optional(bool, null)
    is_scsi_controller_enabled = optional(bool, null)
    is_agent_vm                = optional(bool, null)
    generation_uuid            = optional(string, null)
    bios_uuid                  = optional(string, null)
  }))

  default = []
}
