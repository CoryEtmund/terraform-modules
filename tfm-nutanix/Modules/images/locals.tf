###############################################################################
# Images Module — Locals
###############################################################################

locals {
  # Build a name → ext_id lookup map from all discovered images
  all_images = {
    for image in data.nutanix_images_v2.all.image_entities :
    image.name => image.ext_id
  }

  # If a filter list was provided, narrow down; otherwise return all
  images = length(var.images) > 0 ? {
    for name, id in local.all_images : name => id
    if contains(var.images, name)
  } : local.all_images
}
