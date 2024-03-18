# We strongly recommend using the required_providers block to set the
# Azure Provider source and version being used
terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "=3.0.0"
    }
  }
}

# Configure the Microsoft Azure Provider
provider "azurerm" {
  features {}
}

resource "azurerm_resource_group" "web_rg" {
  name = "panduhz_front_end_rg"
  location = "westus2"
}

resource "azurerm_storage_account" "front_end" {
  name                     = "panduhz_front_storageacct"
  resource_group_name      = azurerm_resource_group.web_rg.name
  location                 = azurerm_resource_group.web_rg.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
  
  static_website {
    index_document = "index.html"
    error_404_document = "error.html"
  }
}

resource "azurerm_storage_blob" "index_html" {
  name                   = "index.html"
  storage_account_name   = azurerm_storage_account.front_end.name
  storage_container_name = "$web"  # Use the $web container for static website files
  type                   = "Block"
  source                 = "path/to/your/index.html"
  content_type = "text/html"
  # Other configurations like content_type may be necessary depending on your files
}

resource "azurerm_storage_blob" "error_html" {
  name                   = "error.html"
  storage_account_name   = azurerm_storage_account.front_end.name
  storage_container_name = "$web"  # Use the $web container for static website files
  type                   = "Block"
  content_type = "text/css"
  # Other configurations like content_type may be necessary depending on your files
}

resource "azurerm_storage_blob" "script_js" {
  name                   = "script.js"
  storage_account_name   = azurerm_storage_account.front_end.name
  storage_container_name = "$web"
  type                   = "Block"
  source                 = "path/to/your/script.js"
  content_type           = "application/javascript"
}