###############################################################################
# nutanix_virtual_machine_v2 — Complete Resource Definition
#
# A single resource block manages ALL VMs (both new and imported).  Import
# blocks in imports.tf handle bringing existing VMs into state.
###############################################################################

resource "nutanix_virtual_machine_v2" "vm" {
  for_each = local.vms

  #---------------------------------------------------------------------------
  # Identity
  #---------------------------------------------------------------------------
  name        = each.value.name
  description = each.value.description

  #---------------------------------------------------------------------------
  # Cluster & Placement
  #---------------------------------------------------------------------------
  cluster {
    ext_id = each.value.cluster.ext_id
  }

  dynamic "host" {
    for_each = each.value.host != null ? [each.value.host] : []
    content {
      ext_id = host.value.ext_id
    }
  }

  dynamic "availability_zone" {
    for_each = each.value.availability_zone != null ? [each.value.availability_zone] : []
    content {
      ext_id = availability_zone.value.ext_id
    }
  }

  #---------------------------------------------------------------------------
  # Compute — CPU
  #---------------------------------------------------------------------------
  num_sockets          = each.value.num_sockets
  num_cores_per_socket = each.value.num_cores_per_socket
  num_threads_per_core = each.value.num_threads_per_core
  num_numa_nodes       = each.value.num_numa_nodes
  power_state          = each.value.power_state

  is_vcpu_hard_pinning_enabled = each.value.is_vcpu_hard_pinning_enabled
  is_cpu_passthrough_enabled   = each.value.is_cpu_passthrough_enabled
  enabled_cpu_features         = each.value.enabled_cpu_features
  is_cpu_hotplug_enabled       = each.value.is_cpu_hotplug_enabled

  #---------------------------------------------------------------------------
  # Compute — Memory
  #---------------------------------------------------------------------------
  memory_size_bytes            = each.value.memory_size_bytes
  is_memory_overcommit_enabled = each.value.is_memory_overcommit_enabled

  #---------------------------------------------------------------------------
  # Machine Type & Boot Config
  #---------------------------------------------------------------------------
  machine_type = each.value.machine_type

  dynamic "boot_config" {
    for_each = each.value.boot_config != null ? [each.value.boot_config] : []
    content {

      dynamic "legacy_boot" {
        for_each = boot_config.value.legacy_boot != null ? [boot_config.value.legacy_boot] : []
        content {
          boot_order = legacy_boot.value.boot_order

          dynamic "boot_device" {
            for_each = legacy_boot.value.boot_device != null ? [legacy_boot.value.boot_device] : []
            content {

              dynamic "disk" {
                for_each = boot_device.value.disk != null ? [boot_device.value.disk] : []
                content {
                  dynamic "disk_address" {
                    for_each = disk.value.disk_address != null ? [disk.value.disk_address] : []
                    content {
                      bus_type = disk_address.value.bus_type
                      index    = disk_address.value.index
                    }
                  }
                }
              }

              dynamic "nic" {
                for_each = boot_device.value.nic != null ? [boot_device.value.nic] : []
                content {
                  mac_address = nic.value.mac_address
                }
              }
            }
          }
        }
      }

      dynamic "uefi_boot" {
        for_each = boot_config.value.uefi_boot != null ? [boot_config.value.uefi_boot] : []
        content {
          is_secure_boot_enabled = uefi_boot.value.is_secure_boot_enabled

          dynamic "nvram_device" {
            for_each = uefi_boot.value.nvram_device != null ? [uefi_boot.value.nvram_device] : []
            content {
              dynamic "backing_storage_info" {
                for_each = nvram_device.value.backing_storage_info != null ? [nvram_device.value.backing_storage_info] : []
                content {
                  disk_size_bytes = backing_storage_info.value.disk_size_bytes

                  dynamic "storage_container" {
                    for_each = backing_storage_info.value.storage_container != null ? [backing_storage_info.value.storage_container] : []
                    content {
                      ext_id = storage_container.value.ext_id
                    }
                  }

                  dynamic "data_source" {
                    for_each = backing_storage_info.value.data_source != null ? [backing_storage_info.value.data_source] : []
                    content {
                      dynamic "reference" {
                        for_each = data_source.value.reference != null ? [data_source.value.reference] : []
                        content {
                          dynamic "image_reference" {
                            for_each = reference.value.image_reference != null ? [reference.value.image_reference] : []
                            content {
                              image_ext_id = image_reference.value.image_ext_id
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
    }
  }

  #---------------------------------------------------------------------------
  # Disks
  #---------------------------------------------------------------------------
  dynamic "disks" {
    for_each = each.value.disks
    content {

      dynamic "disk_address" {
        for_each = disks.value.disk_address != null ? [disks.value.disk_address] : []
        content {
          bus_type = disk_address.value.bus_type
          index    = disk_address.value.index
        }
      }

      dynamic "backing_info" {
        for_each = disks.value.backing_info != null ? [disks.value.backing_info] : []
        content {

          dynamic "vm_disk" {
            for_each = backing_info.value.vm_disk != null ? [backing_info.value.vm_disk] : []
            content {
              disk_size_bytes = vm_disk.value.disk_size_bytes

              dynamic "storage_container" {
                for_each = vm_disk.value.storage_container != null ? [vm_disk.value.storage_container] : []
                content {
                  ext_id = storage_container.value.ext_id
                }
              }

              dynamic "storage_config" {
                for_each = vm_disk.value.storage_config != null ? [vm_disk.value.storage_config] : []
                content {
                  is_flash_mode_enabled = storage_config.value.is_flash_mode_enabled
                }
              }

              dynamic "data_source" {
                for_each = vm_disk.value.data_source != null ? [vm_disk.value.data_source] : []
                content {
                  dynamic "reference" {
                    for_each = data_source.value.reference != null ? [data_source.value.reference] : []
                    content {
                      dynamic "image_reference" {
                        for_each = reference.value.image_reference != null ? [reference.value.image_reference] : []
                        content {
                          image_ext_id = image_reference.value.image_ext_id
                        }
                      }
                      dynamic "vm_disk_reference" {
                        for_each = reference.value.vm_disk_reference != null ? [reference.value.vm_disk_reference] : []
                        content {
                          disk_ext_id = vm_disk_reference.value.disk_ext_id

                          dynamic "disk_address" {
                            for_each = vm_disk_reference.value.disk_address != null ? [vm_disk_reference.value.disk_address] : []
                            content {
                              bus_type = disk_address.value.bus_type
                              index    = disk_address.value.index
                            }
                          }

                          dynamic "vm_reference" {
                            for_each = vm_disk_reference.value.vm_reference != null ? [vm_disk_reference.value.vm_reference] : []
                            content {
                              ext_id = vm_reference.value.ext_id
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

          dynamic "adfs_volume_group_reference" {
            for_each = backing_info.value.adfs_volume_group_reference != null ? [backing_info.value.adfs_volume_group_reference] : []
            content {
              volume_group_ext_id = adfs_volume_group_reference.value.volume_group_ext_id
            }
          }
        }
      }
    }
  }

  #---------------------------------------------------------------------------
  # CD-ROMs
  #---------------------------------------------------------------------------
  dynamic "cd_roms" {
    for_each = each.value.cd_roms
    content {

      dynamic "disk_address" {
        for_each = cd_roms.value.disk_address != null ? [cd_roms.value.disk_address] : []
        content {
          bus_type = disk_address.value.bus_type
          index    = disk_address.value.index
        }
      }

      dynamic "backing_info" {
        for_each = cd_roms.value.backing_info != null ? [cd_roms.value.backing_info] : []
        content {
          dynamic "data_source" {
            for_each = backing_info.value.data_source != null ? [backing_info.value.data_source] : []
            content {
              dynamic "reference" {
                for_each = data_source.value.reference != null ? [data_source.value.reference] : []
                content {
                  dynamic "image_reference" {
                    for_each = reference.value.image_reference != null ? [reference.value.image_reference] : []
                    content {
                      image_ext_id = image_reference.value.image_ext_id
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

  #---------------------------------------------------------------------------
  # NICs
  #---------------------------------------------------------------------------
  dynamic "nics" {
    for_each = each.value.nics
    content {

      dynamic "backing_info" {
        for_each = nics.value.backing_info != null ? [nics.value.backing_info] : []
        content {
          model        = backing_info.value.model
          mac_address  = backing_info.value.mac_address
          is_connected = backing_info.value.is_connected
          num_queues   = backing_info.value.num_queues
        }
      }

      dynamic "network_info" {
        for_each = nics.value.network_info != null ? [nics.value.network_info] : []
        content {
          nic_type  = network_info.value.nic_type
          vlan_mode = network_info.value.vlan_mode

          subnet {
            ext_id = network_info.value.subnet.ext_id
          }

          dynamic "network_function_chain" {
            for_each = network_info.value.network_function_chain != null ? [network_info.value.network_function_chain] : []
            content {
              ext_id = network_function_chain.value.ext_id
            }
          }

          network_function_nic_type = network_info.value.network_function_nic_type

          dynamic "ipv4_config" {
            for_each = network_info.value.ipv4_config != null ? [network_info.value.ipv4_config] : []
            content {
              should_assign_ip = ipv4_config.value.should_assign_ip

              dynamic "ip_address" {
                for_each = ipv4_config.value.ip_address != null ? [ipv4_config.value.ip_address] : []
                content {
                  value         = ip_address.value.value
                  prefix_length = ip_address.value.prefix_length
                }
              }

              dynamic "secondary_ip_address_list" {
                for_each = ipv4_config.value.secondary_ip_address_list != null ? ipv4_config.value.secondary_ip_address_list : []
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
  }

  #---------------------------------------------------------------------------
  # GPUs
  #---------------------------------------------------------------------------
  dynamic "gpus" {
    for_each = each.value.gpus
    content {
      vendor    = gpus.value.vendor
      mode      = gpus.value.mode
      device_id = gpus.value.device_id
    }
  }

  #---------------------------------------------------------------------------
  # Serial Ports
  #---------------------------------------------------------------------------
  dynamic "serial_ports" {
    for_each = each.value.serial_ports
    content {
      index        = serial_ports.value.index
      is_connected = serial_ports.value.is_connected
    }
  }

  #---------------------------------------------------------------------------
  # Guest Customization
  #---------------------------------------------------------------------------
  dynamic "guest_customization" {
    for_each = each.value.guest_customization != null ? [each.value.guest_customization] : []
    content {

      dynamic "config" {
        for_each = guest_customization.value.config != null ? [guest_customization.value.config] : []
        content {

          dynamic "cloud_init" {
            for_each = config.value.cloud_init != null ? [config.value.cloud_init] : []
            content {
              datasource_type = cloud_init.value.datasource_type
              metadata        = cloud_init.value.metadata

              dynamic "cloud_init_script" {
                for_each = cloud_init.value.cloud_init_script != null ? [cloud_init.value.cloud_init_script] : []
                content {
                  dynamic "user_data" {
                    for_each = cloud_init_script.value.user_data != null ? [cloud_init_script.value.user_data] : []
                    content {
                      value = user_data.value.value
                    }
                  }

                  dynamic "custom_key_values" {
                    for_each = cloud_init_script.value.custom_key_values != null ? [cloud_init_script.value.custom_key_values] : []
                    content {
                      dynamic "key_value_pairs" {
                        for_each = custom_key_values.value.key_value_pairs != null ? custom_key_values.value.key_value_pairs : []
                        content {
                          name  = key_value_pairs.value.name
                          value = key_value_pairs.value.value
                        }
                      }
                    }
                  }
                }
              }
            }
          }

          dynamic "sysprep" {
            for_each = config.value.sysprep != null ? [config.value.sysprep] : []
            content {
              install_type = sysprep.value.install_type

              dynamic "sysprep_script" {
                for_each = sysprep.value.sysprep_script != null ? [sysprep.value.sysprep_script] : []
                content {
                  dynamic "unattend_xml" {
                    for_each = sysprep_script.value.unattend_xml != null ? [sysprep_script.value.unattend_xml] : []
                    content {
                      value = unattend_xml.value.value
                    }
                  }

                  dynamic "custom_key_values" {
                    for_each = sysprep_script.value.custom_key_values != null ? [sysprep_script.value.custom_key_values] : []
                    content {
                      dynamic "key_value_pairs" {
                        for_each = custom_key_values.value.key_value_pairs != null ? custom_key_values.value.key_value_pairs : []
                        content {
                          name  = key_value_pairs.value.name
                          value = key_value_pairs.value.value
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

  #---------------------------------------------------------------------------
  # Guest Tools (NGT)
  #---------------------------------------------------------------------------
  dynamic "guest_tools" {
    for_each = each.value.guest_tools != null ? [each.value.guest_tools] : []
    content {
      is_enabled   = guest_tools.value.is_enabled
      capabilities = guest_tools.value.capabilities
    }
  }

  #---------------------------------------------------------------------------
  # Storage Configuration
  #---------------------------------------------------------------------------
  dynamic "storage_config" {
    for_each = each.value.storage_config != null ? [each.value.storage_config] : []
    content {
      is_flash_mode_enabled = storage_config.value.is_flash_mode_enabled

      dynamic "qos_config" {
        for_each = storage_config.value.qos_config != null ? [storage_config.value.qos_config] : []
        content {
          throttled_iops = qos_config.value.throttled_iops
        }
      }
    }
  }

  #---------------------------------------------------------------------------
  # Security — vTPM
  #---------------------------------------------------------------------------
  dynamic "vtpm_config" {
    for_each = each.value.vtpm_config != null ? [each.value.vtpm_config] : []
    content {
      is_vtpm_enabled = vtpm_config.value.is_vtpm_enabled
      version         = vtpm_config.value.version
    }
  }

  #---------------------------------------------------------------------------
  # APC (Advanced Processor Compatibility)
  #---------------------------------------------------------------------------
  dynamic "apc_config" {
    for_each = each.value.apc_config != null ? [each.value.apc_config] : []
    content {
      is_apc_enabled = apc_config.value.is_apc_enabled

      dynamic "cpu_model" {
        for_each = apc_config.value.cpu_model != null ? [apc_config.value.cpu_model] : []
        content {
          ext_id = cpu_model.value.ext_id
        }
      }
    }
  }

  #---------------------------------------------------------------------------
  # Categories
  #---------------------------------------------------------------------------
  dynamic "categories" {
    for_each = each.value.categories != null ? each.value.categories : []
    content {
      ext_id = categories.value.ext_id
    }
  }

  #---------------------------------------------------------------------------
  # Project
  #---------------------------------------------------------------------------
  dynamic "project" {
    for_each = each.value.project != null ? [each.value.project] : []
    content {
      ext_id = project.value.ext_id
    }
  }

  #---------------------------------------------------------------------------
  # Ownership
  #---------------------------------------------------------------------------
  dynamic "ownership_info" {
    for_each = each.value.ownership_info != null ? [each.value.ownership_info] : []
    content {
      owner {
        ext_id = ownership_info.value.owner.ext_id
      }
    }
  }

  #---------------------------------------------------------------------------
  # Protection
  #---------------------------------------------------------------------------
  protection_type = each.value.protection_type

  #---------------------------------------------------------------------------
  # Miscellaneous
  #---------------------------------------------------------------------------
  source                     = each.value.source
  hardware_clock_timezone    = each.value.hardware_clock_timezone
  is_vga_console_enabled     = each.value.is_vga_console_enabled
  is_gpu_console_enabled     = each.value.is_gpu_console_enabled
  is_branding_enabled        = each.value.is_branding_enabled
  is_scsi_controller_enabled = each.value.is_scsi_controller_enabled
  is_agent_vm                = each.value.is_agent_vm
  generation_uuid            = each.value.generation_uuid
  bios_uuid                  = each.value.bios_uuid

  #---------------------------------------------------------------------------
  # Lifecycle — prevent accidental destruction of imported VMs
  #---------------------------------------------------------------------------
  lifecycle {
    prevent_destroy = false # Set to true in production to protect imported VMs
  }
}
