locals {
  vms = { for vm in var.virtual_machines : vm.name => vm }
}