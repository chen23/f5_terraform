# Main

# Terraform Version Pinning
terraform {
  required_version = "~> 0.12"
  required_providers {
    azurerm = "~> 2"
  }
}

# Azure Provider
provider "azurerm" {
  features {}
  subscription_id = var.sp_subscription_id
  client_id       = var.sp_client_id
  client_secret   = var.sp_client_secret
  tenant_id       = var.sp_tenant_id
}

# Create a random id
resource "random_id" id {
  byte_length = 2
}

# Create a resource group
resource "azurerm_resource_group" "rg" {
  name     = format("%s-rg-%s", var.prefix, random_id.id.hex)
  location = var.location
}

# Create Log Analytic Workspace
resource "azurerm_log_analytics_workspace" "law" {
  name                = format("%s-law-%s", var.prefix, random_id.id.hex)
  sku                 = "PerNode"
  retention_in_days   = 300
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
}

# Create the Storage Account
resource "azurerm_storage_account" "mystorage" {
  name                     = format("%sstorage%s", var.prefix, random_id.id.hex)
  resource_group_name      = azurerm_resource_group.rg.name
  location                 = azurerm_resource_group.rg.location
  account_tier             = "Standard"
  account_replication_type = "LRS"

  tags = {
    environment = var.environment
    costcenter  = var.costcenter
  }
}
