variable "directory_service" {
  type = map(object({
    #name                    = string
    alias                   = string
    description             = optional(string, "")
    type                    = optional(string, "MicrosoftAD")
    password                = string
    edition                 = optional(string, "Enterprise")
    domain_controller_count = optional(number, 2)
    short_name              = optional(string)
    enable_sso              = optional(bool, false)
  }))
}

#variable "name" {
#  type = string
#}
# 
#variable "alias" {
#  type = string
#}
# 
#variable "description" {
#  type = optional(string)
#  default = ""
#}
# 
#variable "type" {
#  type = optional(string)
#  default = "MicrosoftAD"
#}
# 
#variable "edition" {
#  type = optional(string)
#  default = "Enterprise"
#}
# 
#variable "domain_controller_count" {
#  type = optional(number)
#  default = 2
#}
# 
#variable "short_name" {
#  type = optional(string)
#}
# 
#variable "enable_sso" {
#  type = optional(bool)
#  default = false
#}
# 
#variable "vpc_settings" {
#  type = object({
#    vpc = string
#    subnets = list(string)
#  })
#}
 
#variable "" {
#  type =
#}
#
#variable "" {
#  type =
#}
#