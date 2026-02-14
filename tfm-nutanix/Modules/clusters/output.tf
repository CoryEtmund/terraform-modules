###############################################################################
# Clusters Module — Outputs
###############################################################################

output "cluster_map" {
  description = "Map of cluster name → ext_id."
  value       = local.clusters
}

output "all_clusters" {
  description = "Map of every discovered cluster name → ext_id."
  value       = local.all_clusters
}
