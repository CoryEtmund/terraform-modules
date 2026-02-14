###############################################################################
# Images Module — Outputs
###############################################################################

output "image_map" {
  description = "Map of image name → ext_id."
  value       = local.images
}

output "all_images" {
  description = "Map of every discovered image name → ext_id."
  value       = local.all_images
}
