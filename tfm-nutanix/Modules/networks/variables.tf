###############################################################################
# Networks (Subnets) Module — Variables
###############################################################################

variable "subnets" {
  description = "Optional list of subnet names to filter. If empty, all subnets are returned."
  type        = list(string)
  default     = []
}
