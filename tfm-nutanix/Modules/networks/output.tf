###############################################################################
# Networks (Subnets) Module — Outputs
###############################################################################

output "subnet_map" {
  description = "Map of subnet name → ext_id."
  value       = local.subnets
}

output "all_subnets" {
  description = "Map of every discovered subnet name → ext_id."
  value       = local.all_subnets
}
