###############################################################################
# Clusters Module — Locals
###############################################################################

locals {
  # Build a name → ext_id lookup map from all discovered clusters
  all_clusters = {
    for cluster in data.nutanix_clusters_v2.all.cluster_entities :
    cluster.name => cluster.ext_id
  }

  # If a filter list was provided, narrow down; otherwise return all
  clusters = length(var.clusters) > 0 ? {
    for name, id in local.all_clusters : name => id
    if contains(var.clusters, name)
  } : local.all_clusters
}
