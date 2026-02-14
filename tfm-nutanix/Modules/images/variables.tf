###############################################################################
# Images Module — Variables
###############################################################################

variable "images" {
  description = "Optional list of image names to filter. If empty, all images are returned."
  type        = list(string)
  default     = []
}
