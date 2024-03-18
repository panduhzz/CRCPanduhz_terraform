# We strongly recommend using the required_providers block to set the
# Azure Provider source and version being used
terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "3.96.0"
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
  
  #Defines that the storage account will be a static website which automatically creates a '$web' blob
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

#CDN and DNS Configuration
resource "azurerm_dns_zone" "panduhz_dns_zone" {
  name = "panduhz.com"
  resource_group_name = azurerm_resource_group.web_rg.name
}
#configuring CNAME for dns zone
resource "azurerm_dns_cname_record" "azure_resource" {
  name                = "target"
  zone_name           = azurerm_dns_zone.panduhz_dns_zone.name
  resource_group_name = azurerm_resource_group.web_rg.name
  ttl                 = 300
  target_resource_id              = "${azurerm_storage_account.front_end.primary_web_host}"
}
#alias reference CNAME
resource "azurerm_dns_cname_record" "target" {
  name                = "www"
  zone_name           = azurerm_dns_zone.panduhz_dns_zone.name
  resource_group_name = azurerm_resource_group.web_rg.name
  ttl                 = 300
  record  = "panduhz.com"
}
resource "azurerm_cdn_frontdoor_profile" "panduhz_door" {
  name = "panduhz_profile"
  resource_group_name = azurerm_resource_group.web_rg.name
  sku_name = "Standard_AzureFrontDoor"
}
resource "azurerm_cdn_frontdoor_custom_domain" "fd_custom" {
  name = "customdomain_frontdoor"
  cdn_frontdoor_profile_id = azurerm_cdn_frontdoor_profile.panduhz_door.id
  dns_zone_id = azurerm_dns_zone.panduhz_dns_zone.id
  host_name = "panduhz.com"

  tls {
    certificate_type = "ManagedCertificate"
    minimum_tls_version = "TLS12"
  }
}