###############################################################################
# nutanix_virtual_machine_v2 — Complete Resource Definition
#
# This single resource block manages ALL VMs (both new and imported).
# Flat variable inputs are mapped to the provider's nested block schema here.
# Name-based fields are resolved to ext_ids via the lookup maps in locals.tf.
###############################################################################

resource "nutanix_virtual_machine_v2" "vm" {
  for_each = local.vms

  # ===========================================================================
  # Identity
  # ===========================================================================
  name        = each.value.name
  description = each.value.description

  # ===========================================================================
  # Cluster (name → ext_id lookup)
  # ===========================================================================
  cluster {
    ext_id = local.cluster_map[each.value.cluster_name]
  }

  # ===========================================================================
  # Host (optional — ext_id)
  # ===========================================================================
  dynamic "host" {
    for_each = each.value.host_ext_id != null ? [1] : []
    content {
      ext_id = each.value.host_ext_id
    }
  }

  # ===========================================================================
  # Availability Zone (optional — ext_id)
  # ===========================================================================
  dynamic "availability_zone" {
    for_each = each.value.availability_zone_ext_id != null ? [1] : []
    content {
      ext_id = each.value.availability_zone_ext_id
    }
  }

  # ===========================================================================
  # Compute — CPU
  # ===========================================================================
  num_sockets          = each.value.num_sockets
  num_cores_per_socket = each.value.num_cores_per_socket
  num_threads_per_core = each.value.num_threads_per_core
  num_numa_nodes       = each.value.num_numa_nodes
  power_state          = each.value.power_state

  is_vcpu_hard_pinning_enabled = each.value.is_vcpu_hard_pinning_enabled
  is_cpu_passthrough_enabled   = each.value.is_cpu_passthrough_enabled
  enabled_cpu_features         = each.value.enabled_cpu_features
  is_cpu_hotplug_enabled       = each.value.is_cpu_hotplug_enabled

  # ===========================================================================
  # Compute — Memory
  # ===========================================================================
  memory_size_bytes            = each.value.memory_size_bytes
  is_memory_overcommit_enabled = each.value.is_memory_overcommit_enabled

  # ===========================================================================
  # Machine Type
  # ===========================================================================
  machine_type = each.value.machine_type

  # ===========================================================================
  # Boot Configuration
  # ===========================================================================
  dynamic "boot_config" {
    for_each = each.value.boot_config != null ? [each.value.boot_config] : []
    content {

      # -----------------------------------------------------------------------
      # Legacy BIOS Boot
      # -----------------------------------------------------------------------
      dynamic "legacy_boot" {
        for_each = boot_config.value.boot_type == "legacy" ? [1] : []
        content {
          boot_order = boot_config.value.boot_order

          dynamic "boot_device" {
            for_each = (boot_config.value.boot_disk_bus_type != null || boot_config.value.boot_nic_mac != null) ? [1] : []
            content {
              dynamic "disk" {
                for_each = boot_config.value.boot_disk_bus_type != null ? [1] : []
                content {
                  disk_address {
                    bus_type = boot_config.value.boot_disk_bus_type
                    index    = boot_config.value.boot_disk_index
                  }
                }
              }

              dynamic "nic" {
                for_each = boot_config.value.boot_nic_mac != null ? [1] : []
                content {
                  mac_address = boot_config.value.boot_nic_mac
                }
              }
            }
          }
        }
      }

      # -----------------------------------------------------------------------
      # UEFI Boot
      # -----------------------------------------------------------------------
      dynamic "uefi_boot" {
        for_each = boot_config.value.boot_type == "uefi" ? [1] : []
        content {
          is_secure_boot_enabled = boot_config.value.is_secure_boot_enabled

          dynamic "nvram_device" {
            for_each = boot_config.value.nvram_disk_size_bytes != null ? [1] : []
            content {
              backing_storage_info {
                disk_size_bytes = boot_config.value.nvram_disk_size_bytes

                dynamic "storage_container" {
                  for_each = boot_config.value.nvram_storage_container_name != null ? [1] : []
                  content {
                    ext_id = local.storage_container_map[boot_config.value.nvram_storage_container_name]
                  }
                }

                dynamic "data_source" {
                  for_each = boot_config.value.nvram_image_name != null ? [1] : []
                  content {
                    reference {
                      image_reference {
                        image_ext_id = local.image_map[boot_config.value.nvram_image_name]
                      }
                    }
                  }
                }
              }
            }
          }
        }
      }
    }
  }

  # ===========================================================================
  # Disks
  #
  # Flat input → nested resource mapping:
  #   bus_type / index              → disks.disk_address
  #   storage_container_name        → backing_info.vm_disk.storage_container  (name lookup)
  #   image_name                    → backing_info.vm_disk.data_source        (name lookup)
  #   clone_from_vm_disk            → backing_info.vm_disk.data_source.vm_disk_reference
  #   volume_group_ext_id           → backing_info.adfs_volume_group_reference
  # ===========================================================================
  dynamic "disks" {
    for_each = each.value.disks
    content {

      disk_address {
        bus_type = disks.value.bus_type
        index    = disks.value.index
      }

      dynamic "backing_info" {
        for_each = (
          disks.value.disk_size_bytes != null ||
          disks.value.storage_container_name != null ||
          disks.value.image_name != null ||
          disks.value.clone_from_vm_disk != null ||
          disks.value.volume_group_ext_id != null
        ) ? [1] : []
        content {

          # --- VM Disk (standard disk, not a volume group) ---
          dynamic "vm_disk" {
            for_each = disks.value.volume_group_ext_id == null ? [1] : []
            content {
              disk_size_bytes = disks.value.disk_size_bytes

              dynamic "storage_container" {
                for_each = disks.value.storage_container_name != null ? [1] : []
                content {
                  ext_id = local.storage_container_map[disks.value.storage_container_name]
                }
              }

              dynamic "storage_config" {
                for_each = disks.value.is_flash_mode_enabled != null ? [1] : []
                content {
                  is_flash_mode_enabled = disks.value.is_flash_mode_enabled
                }
              }

              # Data source: clone from image OR from another VM's disk
              dynamic "data_source" {
                for_each = (disks.value.image_name != null || disks.value.clone_from_vm_disk != null) ? [1] : []
                content {
                  reference {

                    # Clone from image (name lookup)
                    dynamic "image_reference" {
                      for_each = disks.value.image_name != null ? [1] : []
                      content {
                        image_ext_id = local.image_map[disks.value.image_name]
                      }
                    }

                    # Clone from another VM's disk (ext_id based)
                    dynamic "vm_disk_reference" {
                      for_each = disks.value.clone_from_vm_disk != null ? [disks.value.clone_from_vm_disk] : []
                      content {
                        disk_ext_id = vm_disk_reference.value.disk_ext_id

                        dynamic "disk_address" {
                          for_each = vm_disk_reference.value.bus_type != null ? [1] : []
                          content {
                            bus_type = vm_disk_reference.value.bus_type
                            index    = vm_disk_reference.value.index
                          }
                        }

                        dynamic "vm_reference" {
                          for_each = vm_disk_reference.value.vm_ext_id != null ? [1] : []
                          content {
                            ext_id = vm_disk_reference.value.vm_ext_id
                          }
                        }
                      }
                    }
                  }
                }
              }
            }
          }

          # --- Volume Group (ADFS) ---
          dynamic "adfs_volume_group_reference" {
            for_each = disks.value.volume_group_ext_id != null ? [1] : []
            content {
              volume_group_ext_id = disks.value.volume_group_ext_id
            }
          }
        }
      }
    }
  }

  # ===========================================================================
  # CD-ROMs
  # ===========================================================================
  dynamic "cd_roms" {
    for_each = each.value.cd_roms
    content {

      disk_address {
        bus_type = cd_roms.value.bus_type
        index    = cd_roms.value.index
      }

      dynamic "backing_info" {
        for_each = cd_roms.value.image_name != null ? [1] : []
        content {
          data_source {
            reference {
              image_reference {
                image_ext_id = local.image_map[cd_roms.value.image_name]
              }
            }
          }
        }
      }
    }
  }

  # ===========================================================================
  # NICs
  #
  # Flat input → nested resource mapping:
  #   subnet_name     → network_info.subnet         (name lookup)
  #   model, etc.     → backing_info
  #   ip_address      → network_info.ipv4_config
  # ===========================================================================
  dynamic "nics" {
    for_each = each.value.nics
    content {

      backing_info {
        model        = nics.value.model
        mac_address  = nics.value.mac_address
        is_connected = nics.value.is_connected
        num_queues   = nics.value.num_queues
      }

      network_info {
        nic_type  = nics.value.nic_type
        vlan_mode = nics.value.vlan_mode

        subnet {
          ext_id = local.subnet_map[nics.value.subnet_name]
        }

        dynamic "network_function_chain" {
          for_each = nics.value.network_function_chain_ext_id != null ? [1] : []
          content {
            ext_id = nics.value.network_function_chain_ext_id
          }
        }

        network_function_nic_type = nics.value.network_function_nic_type

        dynamic "ipv4_config" {
          for_each = (nics.value.ip_address != null || nics.value.should_assign_ip != null) ? [1] : []
          content {
            should_assign_ip = nics.value.should_assign_ip

            dynamic "ip_address" {
              for_each = nics.value.ip_address != null ? [1] : []
              content {
                value         = nics.value.ip_address
                prefix_length = nics.value.prefix_length
              }
            }

            dynamic "secondary_ip_address_list" {
              for_each = nics.value.secondary_ips != null ? nics.value.secondary_ips : []
              content {
                value         = secondary_ip_address_list.value.value
                prefix_length = secondary_ip_address_list.value.prefix_length
              }
            }
          }
        }
      }
    }
  }

  # ===========================================================================
  # GPUs
  # ===========================================================================
  dynamic "gpus" {
    for_each = each.value.gpus
    content {
      vendor    = gpus.value.vendor
      mode      = gpus.value.mode
      device_id = gpus.value.device_id
    }
  }

  # ===========================================================================
  # Serial Ports
  # ===========================================================================
  dynamic "serial_ports" {
    for_each = each.value.serial_ports
    content {
      index        = serial_ports.value.index
      is_connected = serial_ports.value.is_connected
    }
  }

  # ===========================================================================
  # Guest Customization
  #
  # Flat input → nested resource mapping:
  #   type = "cloud_init" → config.cloud_init block
  #   type = "sysprep"    → config.sysprep block
  # ===========================================================================
  dynamic "guest_customization" {
    for_each = each.value.guest_customization != null ? [each.value.guest_customization] : []
    content {
      config {

        # --- Cloud-Init ---
        dynamic "cloud_init" {
          for_each = guest_customization.value.type == "cloud_init" ? [1] : []
          content {
            datasource_type = guest_customization.value.cloud_init_datasource
            metadata        = guest_customization.value.cloud_init_metadata

            dynamic "cloud_init_script" {
              for_each = (guest_customization.value.cloud_init_user_data != null || guest_customization.value.cloud_init_custom_keys != null) ? [1] : []
              content {

                dynamic "user_data" {
                  for_each = guest_customization.value.cloud_init_user_data != null ? [1] : []
                  content {
                    value = guest_customization.value.cloud_init_user_data
                  }
                }

                dynamic "custom_key_values" {
                  for_each = guest_customization.value.cloud_init_custom_keys != null ? [1] : []
                  content {
                    dynamic "key_value_pairs" {
                      for_each = guest_customization.value.cloud_init_custom_keys
                      content {
                        name = key_value_pairs.value.name
                        value {
                          string = key_value_pairs.value.value
                        }
                      }
                    }
                  }
                }
              }
            }
          }
        }

        # --- Sysprep ---
        dynamic "sysprep" {
          for_each = guest_customization.value.type == "sysprep" ? [1] : []
          content {
            install_type = guest_customization.value.sysprep_install_type

            dynamic "sysprep_script" {
              for_each = (guest_customization.value.sysprep_unattend_xml != null || guest_customization.value.sysprep_custom_keys != null) ? [1] : []
              content {

                dynamic "unattend_xml" {
                  for_each = guest_customization.value.sysprep_unattend_xml != null ? [1] : []
                  content {
                    value = guest_customization.value.sysprep_unattend_xml
                  }
                }

                dynamic "custom_key_values" {
                  for_each = guest_customization.value.sysprep_custom_keys != null ? [1] : []
                  content {
                    dynamic "key_value_pairs" {
                      for_each = guest_customization.value.sysprep_custom_keys
                      content {
                        name = key_value_pairs.value.name
                        value {
                          string = key_value_pairs.value.value
                        }
                      }
                    }
                  }
                }
              }
            }
          }
        }
      }
    }
  }

  # ===========================================================================
  # Guest Tools (NGT)
  # ===========================================================================
  dynamic "guest_tools" {
    for_each = each.value.guest_tools != null ? [each.value.guest_tools] : []
    content {
      is_enabled   = guest_tools.value.is_enabled
      capabilities = guest_tools.value.capabilities
    }
  }

  # ===========================================================================
  # Storage Configuration
  # ===========================================================================
  dynamic "storage_config" {
    for_each = each.value.storage_config != null ? [each.value.storage_config] : []
    content {
      is_flash_mode_enabled = storage_config.value.is_flash_mode_enabled

      dynamic "qos_config" {
        for_each = storage_config.value.throttled_iops != null ? [1] : []
        content {
          throttled_iops = storage_config.value.throttled_iops
        }
      }
    }
  }

  # ===========================================================================
  # Security — vTPM
  # ===========================================================================
  dynamic "vtpm_config" {
    for_each = each.value.vtpm_config != null ? [each.value.vtpm_config] : []
    content {
      is_vtpm_enabled = vtpm_config.value.is_vtpm_enabled
      version         = vtpm_config.value.version
    }
  }

  # ===========================================================================
  # Advanced Processor Compatibility (APC)
  # ===========================================================================
  dynamic "apc_config" {
    for_each = each.value.apc_config != null ? [each.value.apc_config] : []
    content {
      is_apc_enabled = apc_config.value.is_apc_enabled

      dynamic "cpu_model" {
        for_each = apc_config.value.cpu_model_ext_id != null ? [1] : []
        content {
          ext_id = apc_config.value.cpu_model_ext_id
        }
      }
    }
  }

  # ===========================================================================
  # Categories
  # ===========================================================================
  dynamic "categories" {
    for_each = each.value.categories != null ? each.value.categories : []
    content {
      ext_id = categories.value.ext_id
    }
  }

  # ===========================================================================
  # Project
  # ===========================================================================
  dynamic "project" {
    for_each = each.value.project_ext_id != null ? [1] : []
    content {
      ext_id = each.value.project_ext_id
    }
  }

  # ===========================================================================
  # Ownership
  # ===========================================================================
  dynamic "ownership_info" {
    for_each = each.value.owner_ext_id != null ? [1] : []
    content {
      owner {
        ext_id = each.value.owner_ext_id
      }
    }
  }

  # ===========================================================================
  # Protection
  # ===========================================================================
  protection_type = each.value.protection_type

  # ===========================================================================
  # Source (clone from VM / recovery point)
  # ===========================================================================
  dynamic "source" {
    for_each = each.value.source_entity_type != null ? [1] : []
    content {
      entity_type = each.value.source_entity_type
    }
  }

  # ===========================================================================
  # Miscellaneous
  # ===========================================================================
  hardware_clock_timezone    = each.value.hardware_clock_timezone
  is_vga_console_enabled     = each.value.is_vga_console_enabled
  is_gpu_console_enabled     = each.value.is_gpu_console_enabled
  is_branding_enabled        = each.value.is_branding_enabled
  is_scsi_controller_enabled = each.value.is_scsi_controller_enabled
  is_agent_vm                = each.value.is_agent_vm
  generation_uuid            = each.value.generation_uuid
  bios_uuid                  = each.value.bios_uuid

  # ===========================================================================
  # Lifecycle
  # ===========================================================================
  lifecycle {
    prevent_destroy = false # Set to true in production to protect imported VMs
  }
}
