###############################################################################
# Variables — Provider & Subnet Definitions
#
# The subnet schema is intentionally FLAT.  Instead of deeply nested objects
# with ext_ids, you supply human-readable names (cluster_name) and the module
# resolves them to ext_ids via data source lookups.
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
# Subnets (Networks)
# =============================================================================

variable "subnets" {
  description = <<-EOT
    List of subnet (network) definitions.  Each entry creates (or imports) one
    nutanix_subnet_v2 resource.

    Name-based lookups (resolved automatically via data sources):
      - cluster_name → cluster ext_id  (for VLAN subnets)

    Subnet types:
      - "VLAN"    — Layer-2 VLAN-backed subnet attached to a cluster
      - "OVERLAY" — VPC overlay subnet (requires vpc_reference)
  EOT

  type = list(object({

    # ── Identity ──────────────────────────────────────────────────────────────
    name        = string                 # Subnet display name (unique key)
    description = optional(string, null) # Friendly description
    import_uuid = optional(string, null) # Set to ext_id to import existing subnet

    # ── Type & VLAN ───────────────────────────────────────────────────────────
    subnet_type = string           # "VLAN" or "OVERLAY"
    network_id  = optional(number) # VLAN ID (0-4095) for VLAN subnets

    # ── Cluster (name-based lookup) ───────────────────────────────────────────
    cluster_name = optional(string) # Cluster name — resolved to ext_id

    # ── Virtual Switch (UUID) ─────────────────────────────────────────────────
    virtual_switch_reference = optional(string) # UUID of the virtual switch (VLAN only)

    # ── VPC (UUID — for overlay subnets) ──────────────────────────────────────
    vpc_reference = optional(string) # UUID of the VPC (OVERLAY only)

    # ── External / NAT ────────────────────────────────────────────────────────
    is_external    = optional(bool, false) # External connectivity subnet
    is_nat_enabled = optional(bool)        # Enable NAT (external subnets only)

    # ── Advanced Networking ───────────────────────────────────────────────────
    is_advanced_networking            = optional(bool)   # Advanced networking flag
    network_function_chain_reference  = optional(string) # Network function chain UUID (VLAN only)
    bridge_name                       = optional(string) # Bridge name on the host
    ip_prefix                         = optional(string) # IP Prefix in CIDR format

    # ── IP Configuration ──────────────────────────────────────────────────────
    ip_config = optional(list(object({

      # IPv4 Configuration
      ipv4 = optional(object({
        ip_subnet = object({
          ip            = string # Network address (e.g. "192.168.1.0")
          prefix_length = number # CIDR prefix (e.g. 24)
        })
        default_gateway_ip  = optional(string) # Gateway IP address
        dhcp_server_address = optional(string) # DHCP server IP (if external)

        pool_list = optional(list(object({
          start_ip = string # First IP in pool
          end_ip   = string # Last IP in pool
        })), [])
      }))

      # IPv6 Configuration
      ipv6 = optional(object({
        ip_subnet = object({
          ip            = string # Network address
          prefix_length = number # CIDR prefix
        })
        default_gateway_ip  = optional(string) # Gateway IP address
        dhcp_server_address = optional(string) # DHCP server IP

        pool_list = optional(list(object({
          start_ip = string # First IP in pool
          end_ip   = string # Last IP in pool
        })), [])
      }))

    })), [])

    # ── DHCP Options ──────────────────────────────────────────────────────────
    dhcp_options = optional(object({
      domain_name_servers = optional(list(object({
        ipv4 = optional(string) # DNS server IPv4 address
        ipv6 = optional(string) # DNS server IPv6 address
      })), [])
      domain_name      = optional(string)       # DNS domain name
      search_domains   = optional(list(string))  # DNS search domain list
      tftp_server_name = optional(string)        # TFTP server name (PXE boot)
      boot_file_name   = optional(string)        # Boot file name (PXE boot)
      ntp_servers = optional(list(object({
        ipv4 = optional(string) # NTP server IPv4 address
        ipv6 = optional(string) # NTP server IPv6 address
      })), [])
    }))

    # ── Reserved / Dynamic IPs ────────────────────────────────────────────────
    reserved_ip_addresses = optional(list(string), []) # IPs excluded from allocation
    dynamic_ip_addresses = optional(list(object({
      ipv4 = optional(string) # Dynamic IP (IPv4) for SDN gateway
      ipv6 = optional(string) # Dynamic IP (IPv6) for SDN gateway
    })), [])

    # ── Metadata ──────────────────────────────────────────────────────────────
    cluster_name_meta  = optional(string) # Cluster name metadata field
    hypervisor_type    = optional(string) # Hypervisor type metadata

  }))

  default = []
}
