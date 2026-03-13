terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.0"
    }
  }

  backend "azurerm" {
    resource_group_name  = "rg-fiapx-tfst-fx2026"
    storage_account_name = "fiapxtfstfx2026"
    container_name       = "tfstate"
    key                  = "fiapx.tfstate"
  }
}

provider "azurerm" {
  features {}
  # A subscription_id será lida automaticamente de ARM_SUBSCRIPTION_ID
}

# ─────────────────────────────────────────────
# Random suffix pra garantir nomes únicos
# ─────────────────────────────────────────────
resource "random_string" "suffix" {
  length  = 4
  special = false
  upper   = false
}

# ─────────────────────────────────────────────
# Resource Group
# ─────────────────────────────────────────────
resource "azurerm_resource_group" "main" {
  name     = var.resource_group_name
  location = var.location

  tags = {
    Project     = "FIAP X"
    Environment = "Production"
  }
}

# ─────────────────────────────────────────────
# Container Registry (ACR)
# ─────────────────────────────────────────────
resource "azurerm_container_registry" "acr" {
  name                = "fiapxacr${random_string.suffix.result}"
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  sku                 = "Basic"
  admin_enabled       = true

  tags = { Project = "FIAP X" }
}

# ─────────────────────────────────────────────
# AKS Cluster
# ─────────────────────────────────────────────
resource "azurerm_kubernetes_cluster" "aks" {
  name                = "aks-fiapx-${random_string.suffix.result}"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  dns_prefix          = "fiapx${random_string.suffix.result}"

 default_node_pool {
    name           = "default"
    node_count     = 1
    vm_size        = "Standard_E2s_v3" 
  }

  identity {
    type = "SystemAssigned"
  }

  tags = { Project = "FIAP X" }
}

# ACR Pull permission for AKS
resource "azurerm_role_assignment" "aks_acr" {
  principal_id                     = azurerm_kubernetes_cluster.aks.kubelet_identity[0].object_id
  role_definition_name             = "AcrPull"
  scope                            = azurerm_container_registry.acr.id
  skip_service_principal_aad_check = true
}

# ─────────────────────────────────────────────
# SQL Server + Database
# ─────────────────────────────────────────────
resource "azurerm_mssql_server" "sql" {
  name                         = "fiapx-sql-${random_string.suffix.result}"
  resource_group_name          = azurerm_resource_group.main.name
  location                     = azurerm_resource_group.main.location
  version                      = "12.0"
  administrator_login          = "fiapxadmin"
  administrator_login_password = var.sql_admin_password

  tags = { Project = "FIAP X" }
}

resource "azurerm_mssql_database" "db" {
  name      = "FiapXDb"
  server_id = azurerm_mssql_server.sql.id
  sku_name  = "Basic"

  tags = { Project = "FIAP X" }
}

# Firewall - Allow Azure Services
resource "azurerm_mssql_firewall_rule" "azure" {
  name             = "AllowAzure"
  server_id        = azurerm_mssql_server.sql.id
  start_ip_address = "0.0.0.0"
  end_ip_address   = "0.0.0.0"
}

# ─────────────────────────────────────────────
# Storage Account
# ─────────────────────────────────────────────
resource "azurerm_storage_account" "storage" {
  name                     = "fiapxstor${random_string.suffix.result}"
  resource_group_name      = azurerm_resource_group.main.name
  location                 = azurerm_resource_group.main.location
  account_tier             = "Standard"
  account_replication_type = "LRS"

  tags = { Project = "FIAP X" }
}

resource "azurerm_storage_container" "uploads" {
  name                  = "uploads"
  storage_account_name  = azurerm_storage_account.storage.name
  container_access_type = "private"
}

resource "azurerm_storage_container" "outputs" {
  name                  = "outputs"
  storage_account_name  = azurerm_storage_account.storage.name
  container_access_type = "private"
}
