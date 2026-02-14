###############################################################################
# Clusters Module — Variables
###############################################################################

variable "clusters" {
  description = "Optional list of cluster names to filter. If empty, all clusters are returned."
  type        = list(string)
  default     = []
}
