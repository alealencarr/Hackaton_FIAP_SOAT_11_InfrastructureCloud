# FIAP X - Infraestrutura base no Azure

Terraform para criar recursos no Azure.

## Recursos Criados
- Resource Group
- Azure Container Registry (ACR)
- Azure Kubernetes Service (AKS)
- Azure SQL Database
- Storage Account

## Como usar
1. Configure o secret `AZURE_CREDENTIALS` com o Service Principal
2. Configure o secret `SQL_ADMIN_PASSWORD`
3. Faça merge na main
4. Pipeline cria tudo automaticamente