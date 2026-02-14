###############################################################################
# Virtual Machine Variables — Complete nutanix_virtual_machine_v2 Schema
#
# Every parameter supported by the Nutanix v4 API virtual machine resource is
# represented here.  Heavy use of `optional()` means consumers only need to
# specify the fields they actually care about in their YAML/HCL config.
###############################################################################

variable "virtual_machines" {
  description = "List of virtual machine definitions. Each object maps 1-to-1 with a nutanix_virtual_machine_v2 resource."

  type = list(object({

    #---------------------------------------------------------------------------
    # Identity & Import
    #---------------------------------------------------------------------------
    name        = string                 # (Required) VM display name
    description = optional(string, null) # VM description
    import_uuid = optional(string, null) # If set, this VM will be imported into state rather than created

    #---------------------------------------------------------------------------
    # Cluster & Placement
    #---------------------------------------------------------------------------
    cluster = object({ # (Required) Target cluster
      ext_id = string
    })
    host = optional(object({ # Pin to a specific host
      ext_id = string
    }), null)
    availability_zone = optional(object({ # AZ placement
      ext_id = string
    }), null)

    #---------------------------------------------------------------------------
    # Compute — CPU
    #---------------------------------------------------------------------------
    num_sockets          = number                    # (Required) Number of CPU sockets
    num_cores_per_socket = optional(number, 1)       # Cores per socket
    num_threads_per_core = optional(number, 1)       # Threads per core (SMT)
    num_numa_nodes       = optional(number, 0)       # vNUMA nodes; 0 = disabled
    power_state          = optional(string, "ON")    # ON or OFF

    # CPU feature flags
    is_vcpu_hard_pinning_enabled = optional(bool, null)   # Pin vCPUs to physical cores
    is_cpu_passthrough_enabled   = optional(bool, null)    # Pass host CPU model to guest
    enabled_cpu_features         = optional(list(string), null) # e.g. ["HARDWARE_VIRTUALIZATION"]
    is_cpu_hotplug_enabled       = optional(bool, null)    # Allow hot-adding vCPUs

    #---------------------------------------------------------------------------
    # Compute — Memory
    #---------------------------------------------------------------------------
    memory_size_bytes            = number                       # (Required) Memory in bytes
    is_memory_overcommit_enabled = optional(bool, null)         # Memory overcommit

    #---------------------------------------------------------------------------
    # Machine Type & Boot
    #---------------------------------------------------------------------------
    machine_type = optional(string, null) # PC, Q35, or PSERIES

    boot_config = optional(object({
      legacy_boot = optional(object({
        boot_order = optional(list(string), null) # e.g. ["DISK", "CDROM", "NETWORK"]
        boot_device = optional(object({
          disk = optional(object({
            disk_address = optional(object({
              bus_type = string # SCSI, IDE, PCI, SATA, SPAPR
              index    = number
            }), null)
          }), null)
          nic = optional(object({
            mac_address = optional(string, null)
          }), null)
        }), null)
      }), null)
      uefi_boot = optional(object({
        is_secure_boot_enabled = optional(bool, false)
        nvram_device = optional(object({
          backing_storage_info = optional(object({
            disk_size_bytes = optional(number, null)
            storage_container = optional(object({
              ext_id = string
            }), null)
            data_source = optional(object({
              reference = optional(object({
                image_reference = optional(object({
                  image_ext_id = string
                }), null)
              }), null)
            }), null)
          }), null)
        }), null)
      }), null)
    }), null)

    #---------------------------------------------------------------------------
    # Disks
    #---------------------------------------------------------------------------
    disks = optional(list(object({
      disk_address = optional(object({
        bus_type = string # SCSI, IDE, PCI, SATA, SPAPR
        index    = optional(number, null)
      }), null)
      backing_info = optional(object({
        vm_disk = optional(object({
          disk_size_bytes = optional(number, null)
          storage_container = optional(object({
            ext_id = string
          }), null)
          storage_config = optional(object({
            is_flash_mode_enabled = optional(bool, null)
          }), null)
          data_source = optional(object({
            reference = optional(object({
              image_reference = optional(object({
                image_ext_id = string
              }), null)
              vm_disk_reference = optional(object({
                disk_ext_id       = string
                disk_address      = optional(object({
                  bus_type = string
                  index    = number
                }), null)
                vm_reference = optional(object({
                  ext_id = string
                }), null)
              }), null)
            }), null)
          }), null)
        }), null)
        adfs_volume_group_reference = optional(object({
          volume_group_ext_id = string
        }), null)
      }), null)
    })), [])

    #---------------------------------------------------------------------------
    # CD-ROMs
    #---------------------------------------------------------------------------
    cd_roms = optional(list(object({
      disk_address = optional(object({
        bus_type = optional(string, "IDE") # IDE or SATA
        index    = optional(number, null)
      }), null)
      backing_info = optional(object({
        data_source = optional(object({
          reference = optional(object({
            image_reference = optional(object({
              image_ext_id = string
            }), null)
          }), null)
        }), null)
      }), null)
    })), [])

    #---------------------------------------------------------------------------
    # NICs
    #---------------------------------------------------------------------------
    nics = optional(list(object({
      backing_info = optional(object({
        model        = optional(string, null) # VIRTIO or E1000
        mac_address  = optional(string, null)
        is_connected = optional(bool, true)
        num_queues   = optional(number, null)
      }), null)
      network_info = optional(object({
        nic_type  = optional(string, "NORMAL_NIC") # NORMAL_NIC, DIRECT_NIC, NETWORK_FUNCTION_NIC
        vlan_mode = optional(string, null)          # ACCESS or TRUNK
        subnet = object({
          ext_id = string
        })
        network_function_chain = optional(object({
          ext_id = string
        }), null)
        network_function_nic_type = optional(string, null) # INGRESS, EGRESS, TAP
        ipv4_config = optional(object({
          should_assign_ip = optional(bool, null)
          ip_address = optional(object({
            value       = string
            prefix_length = optional(number, null)
          }), null)
          secondary_ip_address_list = optional(list(object({
            value       = string
            prefix_length = optional(number, null)
          })), null)
        }), null)
      }), null)
    })), [])

    #---------------------------------------------------------------------------
    # GPUs
    #---------------------------------------------------------------------------
    gpus = optional(list(object({
      vendor    = optional(string, null) # e.g. NVIDIA, AMD, INTEL
      mode      = optional(string, null) # PASSTHROUGH_GRAPHICS, PASSTHROUGH_COMPUTE, VIRTUAL
      device_id = optional(number, null)
    })), [])

    #---------------------------------------------------------------------------
    # Serial Ports
    #---------------------------------------------------------------------------
    serial_ports = optional(list(object({
      index        = number
      is_connected = optional(bool, true)
    })), [])

    #---------------------------------------------------------------------------
    # Guest Customization
    #---------------------------------------------------------------------------
    guest_customization = optional(object({
      config = optional(object({
        cloud_init = optional(object({
          datasource_type  = optional(string, "CONFIG_DRIVE_V2") # CONFIG_DRIVE_V2 or CUSTOM
          metadata         = optional(string, null)               # Base64-encoded
          cloud_init_script = optional(object({
            user_data = optional(object({
              value = string # Base64-encoded cloud-init user_data
            }), null)
            custom_key_values = optional(object({
              key_value_pairs = optional(list(object({
                name  = string
                value = optional(string, null)
              })), null)
            }), null)
          }), null)
        }), null)
        sysprep = optional(object({
          install_type = optional(string, "PREPARED") # PREPARED or FRESH
          sysprep_script = optional(object({
            unattend_xml = optional(object({
              value = string # Base64-encoded unattend.xml content
            }), null)
            custom_key_values = optional(object({
              key_value_pairs = optional(list(object({
                name  = string
                value = optional(string, null)
              })), null)
            }), null)
          }), null)
        }), null)
      }), null)
    }), null)

    #---------------------------------------------------------------------------
    # Guest Tools (NGT)
    #---------------------------------------------------------------------------
    guest_tools = optional(object({
      is_enabled   = optional(bool, null)
      capabilities = optional(list(string), null) # e.g. ["SELF_SERVICE_RESTORE", "VSS_SNAPSHOT"]
    }), null)

    #---------------------------------------------------------------------------
    # Storage Configuration
    #---------------------------------------------------------------------------
    storage_config = optional(object({
      is_flash_mode_enabled = optional(bool, null)
      qos_config = optional(object({
        throttled_iops = optional(number, null)
      }), null)
    }), null)

    #---------------------------------------------------------------------------
    # Security — vTPM
    #---------------------------------------------------------------------------
    vtpm_config = optional(object({
      is_vtpm_enabled = optional(bool, false)
      version         = optional(string, null)
    }), null)

    #---------------------------------------------------------------------------
    # Advanced Processor Compatibility (APC)
    #---------------------------------------------------------------------------
    apc_config = optional(object({
      is_apc_enabled  = optional(bool, false)
      cpu_model = optional(object({
        ext_id = optional(string, null)
      }), null)
    }), null)

    #---------------------------------------------------------------------------
    # Categories, Project & Ownership
    #---------------------------------------------------------------------------
    categories = optional(list(object({
      ext_id = string
    })), null)

    project = optional(object({
      ext_id = string
    }), null)

    ownership_info = optional(object({
      owner = object({
        ext_id = string
      })
    }), null)

    #---------------------------------------------------------------------------
    # Protection
    #---------------------------------------------------------------------------
    protection_type = optional(string, null) # UNPROTECTED, PD_PROTECTED, RULE_PROTECTED

    #---------------------------------------------------------------------------
    # Miscellaneous
    #---------------------------------------------------------------------------
    source                   = optional(string, null)  # VM or VM_RECOVERY_POINT (clone source type)
    hardware_clock_timezone  = optional(string, null)  # IANA TZDB timezone
    is_vga_console_enabled   = optional(bool, null)
    is_gpu_console_enabled   = optional(bool, null)
    is_branding_enabled      = optional(bool, null)
    is_scsi_controller_enabled = optional(bool, null)
    is_agent_vm              = optional(bool, null)
    generation_uuid          = optional(string, null)
    bios_uuid                = optional(string, null)
  }))

  default = []
}
