variable "resource_group_name" {
  default = "rg-fiapx-ale10fx"
}

variable "location" {
  default = "brazilsouth"
}

variable "sql_admin_password" {
  sensitive = true
}