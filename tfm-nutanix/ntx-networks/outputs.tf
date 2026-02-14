###############################################################################
# Outputs
###############################################################################

# ---------------------------------------------------------------------------
# Lookup Maps (useful for debugging or external reference)
# ---------------------------------------------------------------------------

output "cluster_map" {
  description = "Map of cluster name → ext_id discovered from Prism Central."
  value       = local.cluster_map
}

# ---------------------------------------------------------------------------
# Subnets
# ---------------------------------------------------------------------------

output "subnets" {
  description = "Map of all managed subnets keyed by name with key attributes."
  value = {
    for name, s in nutanix_subnet_v2.subnet : name => {
      ext_id            = s.ext_id
      name              = s.name
      description       = s.description
      subnet_type       = s.subnet_type
      network_id        = s.network_id
      cluster_reference = s.cluster_reference
      vpc_reference     = s.vpc_reference
      is_external       = s.is_external
      is_nat_enabled    = s.is_nat_enabled
      bridge_name       = s.bridge_name
      ip_prefix         = s.ip_prefix
    }
  }
}

output "subnet_ids" {
  description = "Map of subnet name → ext_id (UUID)."
  value = {
    for name, s in nutanix_subnet_v2.subnet : name => s.ext_id
  }
}

output "subnet_names" {
  description = "List of all managed subnet names."
  value       = [for name, s in nutanix_subnet_v2.subnet : s.name]
}

output "subnet_details" {
  description = "Full resource attributes for each subnet (for downstream modules)."
  value       = nutanix_subnet_v2.subnet
  sensitive   = false
}
