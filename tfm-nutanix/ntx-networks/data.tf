###############################################################################
# Data Sources — Name-Based Lookups
#
# These data sources query Prism Central and build name → ext_id maps so that
# subnet definitions can reference resources by human-readable names instead
# of UUIDs.  The lookup maps are constructed in locals.tf.
###############################################################################

# -----------------------------------------------------------------------------
# Clusters
# -----------------------------------------------------------------------------
data "nutanix_clusters_v2" "all" {}
