###############################################################################
# Nutanix Subnet (Network) Resource — nutanix_subnet_v2
#
# Creates subnets based on the flat, name-driven variable schema defined in
# variables.tf.  Cluster names are resolved to ext_ids via data-source lookups
# in locals.tf.
###############################################################################

resource "nutanix_subnet_v2" "subnet" {
  for_each = local.subnets

  # ── Identity ──────────────────────────────────────────────────────────────
  name        = each.value.name
  description = each.value.description

  # ── Type & VLAN ─────────────────────────────────────────────────────────
  subnet_type = each.value.subnet_type
  network_id  = each.value.network_id

  # ── Cluster Reference (name → ext_id) ──────────────────────────────────
  cluster_reference = (
    each.value.cluster_name != null
    ? local.cluster_map[each.value.cluster_name]
    : null
  )

  # ── Virtual Switch Reference (UUID) ─────────────────────────────────────
  virtual_switch_reference = each.value.virtual_switch_reference

  # ── VPC Reference (UUID — overlay subnets) ──────────────────────────────
  vpc_reference = each.value.vpc_reference

  # ── External / NAT ──────────────────────────────────────────────────────
  is_external    = each.value.is_external
  is_nat_enabled = each.value.is_nat_enabled

  # ── Advanced Networking ─────────────────────────────────────────────────
  is_advanced_networking           = each.value.is_advanced_networking
  network_function_chain_reference = each.value.network_function_chain_reference
  bridge_name                      = each.value.bridge_name
  ip_prefix                        = each.value.ip_prefix

  # ── Metadata ────────────────────────────────────────────────────────────
  cluster_name    = each.value.cluster_name_meta
  hypervisor_type = each.value.hypervisor_type

  # ── Reserved IP Addresses ───────────────────────────────────────────────
  dynamic "reserved_ip_addresses" {
    for_each = each.value.reserved_ip_addresses
    content {
      value = reserved_ip_addresses.value
    }
  }

  # ── Dynamic IP Addresses ────────────────────────────────────────────────
  dynamic "dynamic_ip_addresses" {
    for_each = each.value.dynamic_ip_addresses
    content {
      dynamic "ipv4" {
        for_each = dynamic_ip_addresses.value.ipv4 != null ? [dynamic_ip_addresses.value.ipv4] : []
        content {
          value = ipv4.value
        }
      }
      dynamic "ipv6" {
        for_each = dynamic_ip_addresses.value.ipv6 != null ? [dynamic_ip_addresses.value.ipv6] : []
        content {
          value = ipv6.value
        }
      }
    }
  }

  # ── IP Configuration ───────────────────────────────────────────────────
  dynamic "ip_config" {
    for_each = each.value.ip_config
    content {

      # IPv4
      dynamic "ipv4" {
        for_each = ip_config.value.ipv4 != null ? [ip_config.value.ipv4] : []
        content {
          ip_subnet {
            ip {
              value = ipv4.value.ip_subnet.ip
            }
            prefix_length = ipv4.value.ip_subnet.prefix_length
          }

          dynamic "default_gateway_ip" {
            for_each = ipv4.value.default_gateway_ip != null ? [ipv4.value.default_gateway_ip] : []
            content {
              value = default_gateway_ip.value
            }
          }

          dynamic "dhcp_server_address" {
            for_each = ipv4.value.dhcp_server_address != null ? [ipv4.value.dhcp_server_address] : []
            content {
              value = dhcp_server_address.value
            }
          }

          dynamic "pool_list" {
            for_each = ipv4.value.pool_list
            content {
              start_ip {
                value = pool_list.value.start_ip
              }
              end_ip {
                value = pool_list.value.end_ip
              }
            }
          }
        }
      }

      # IPv6
      dynamic "ipv6" {
        for_each = ip_config.value.ipv6 != null ? [ip_config.value.ipv6] : []
        content {
          ip_subnet {
            ip {
              value = ipv6.value.ip_subnet.ip
            }
            prefix_length = ipv6.value.ip_subnet.prefix_length
          }

          dynamic "default_gateway_ip" {
            for_each = ipv6.value.default_gateway_ip != null ? [ipv6.value.default_gateway_ip] : []
            content {
              value = default_gateway_ip.value
            }
          }

          dynamic "dhcp_server_address" {
            for_each = ipv6.value.dhcp_server_address != null ? [ipv6.value.dhcp_server_address] : []
            content {
              value = dhcp_server_address.value
            }
          }

          dynamic "pool_list" {
            for_each = ipv6.value.pool_list
            content {
              start_ip {
                value = pool_list.value.start_ip
              }
              end_ip {
                value = pool_list.value.end_ip
              }
            }
          }
        }
      }
    }
  }

  # ── DHCP Options ────────────────────────────────────────────────────────
  dynamic "dhcp_options" {
    for_each = each.value.dhcp_options != null ? [each.value.dhcp_options] : []
    content {

      domain_name    = dhcp_options.value.domain_name
      search_domains = dhcp_options.value.search_domains
      tftp_server_name = dhcp_options.value.tftp_server_name
      boot_file_name   = dhcp_options.value.boot_file_name

      dynamic "domain_name_servers" {
        for_each = dhcp_options.value.domain_name_servers
        content {
          dynamic "ipv4" {
            for_each = domain_name_servers.value.ipv4 != null ? [domain_name_servers.value.ipv4] : []
            content {
              value = ipv4.value
            }
          }
          dynamic "ipv6" {
            for_each = domain_name_servers.value.ipv6 != null ? [domain_name_servers.value.ipv6] : []
            content {
              value = ipv6.value
            }
          }
        }
      }

      dynamic "ntp_servers" {
        for_each = dhcp_options.value.ntp_servers
        content {
          dynamic "ipv4" {
            for_each = ntp_servers.value.ipv4 != null ? [ntp_servers.value.ipv4] : []
            content {
              value = ipv4.value
            }
          }
          dynamic "ipv6" {
            for_each = ntp_servers.value.ipv6 != null ? [ntp_servers.value.ipv6] : []
            content {
              value = ipv6.value
            }
          }
        }
      }
    }
  }

  lifecycle {
    ignore_changes = [
      # ip_usage is read-only and may fluctuate — ignore drift
    ]
  }
}
