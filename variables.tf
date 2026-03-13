variable "resource_group_name" {
  description = "Nome do Resource Group principal"
  default     = "rg-fiapx-fx2026"
}

variable "location" {
  description = "Região do Azure"
  default     = "brazilsouth"
}

variable "sql_admin_password" {
  description = "Senha do admin do SQL Server"
  sensitive   = true
}
