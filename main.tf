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
  name     = "panduhz_front_end_rg"
  location = "westus2"
}

resource "azurerm_storage_account" "front_end" {
  name                            = "panduhzstorage"
  resource_group_name             = azurerm_resource_group.web_rg.name
  location                        = azurerm_resource_group.web_rg.location
  account_tier                    = "Standard"
  account_replication_type        = "LRS"
  min_tls_version                 = "TLS1_2"
  allow_nested_items_to_be_public = true

  #Defines that the storage account will be a static website which automatically creates a '$web' blob
  #Have to manually set the $web container to the correct access type.
  static_website {
    index_document     = "index.html"
    error_404_document = "error.html"
  }
}
/*
resource "azurerm_storage_container" "webcontainer" {
  name                  = "$web"
  storage_account_name  = azurerm_storage_account.front_end.name
  container_access_type = "container"
}
*/
resource "azurerm_storage_blob" "index_html" {
  depends_on = [ azurerm_storage_account.front_end ]
  name                   = "index.html"
  storage_account_name   = azurerm_storage_account.front_end.name
  storage_container_name = "$web" # Use the $web container for static website files
  type                   = "Block"
  source                 = "./web/index.html"
  content_type           = "text/html"
  # Other configurations like content_type may be necessary depending on your files
}

resource "azurerm_storage_blob" "syle_css" {
  depends_on = [ azurerm_storage_account.front_end ]
  name                   = "style.css"
  storage_account_name   = azurerm_storage_account.front_end.name
  storage_container_name = "$web" # Use the $web container for static website files
  type                   = "Block"
  source                 = "./web/style.css"
  content_type           = "style/css"
  # Other configurations like content_type may be necessary depending on your files
}

resource "azurerm_storage_blob" "error_html" {
  depends_on = [ azurerm_storage_account.front_end ]
  name                   = "error.html"
  storage_account_name   = azurerm_storage_account.front_end.name
  storage_container_name = "$web" # Use the $web container for static website files
  type                   = "Block"
  source                 = "./web/error.html"
  content_type           = "text/html"
  # Other configurations like content_type may be necessary depending on your files
}

resource "azurerm_storage_blob" "script_js" {
  depends_on = [ azurerm_storage_account.front_end ]
  name                   = "script.js"
  storage_account_name   = azurerm_storage_account.front_end.name
  storage_container_name = "$web"
  type                   = "Block"
  source                 = "./web/script.js"
  content_type           = "application/javascript"
}

#CDN and DNS Configuration
resource "azurerm_dns_zone" "panduhz_dns_zone" {
  name                = "panduhzco.com"
  resource_group_name = azurerm_resource_group.web_rg.name
}

#configuring CNAME for dns zone
resource "azurerm_dns_cname_record" "azure_resource" {
  name                = "cdnverify.www"
  zone_name           = azurerm_dns_zone.panduhz_dns_zone.name
  resource_group_name = azurerm_resource_group.web_rg.name
  ttl                 = 3600
  record              = "cdnverify.${azurerm_cdn_endpoint.example.name}.azureedge.net"
}
#alias reference CNAME
resource "azurerm_dns_cname_record" "target" {
  depends_on          = [azurerm_cdn_endpoint.example]
  name                = "www"
  zone_name           = azurerm_dns_zone.panduhz_dns_zone.name
  resource_group_name = azurerm_resource_group.web_rg.name
  ttl                 = 3600
  target_resource_id  = azurerm_cdn_endpoint.example.id
}
resource "azurerm_cdn_profile" "panduhzprofile" {
  name                = "panduhz-cdn"
  location            = "global"
  resource_group_name = azurerm_resource_group.web_rg.name
  sku                 = "Standard_Microsoft"
}
resource "azurerm_cdn_endpoint" "example" {
  name                = "panduhz-tftest"
  profile_name        = azurerm_cdn_profile.panduhzprofile.name
  location            = "global"
  resource_group_name = azurerm_resource_group.web_rg.name
  is_http_allowed     = true
  is_https_allowed    = true
  origin {
    name      = "default-origin"
    host_name = "${azurerm_storage_account.front_end.name}.blob.core.windows.net"    
  }
  origin_host_header = "${azurerm_storage_account.front_end.name}.blob.core.windows.net"

}

#explicitly creating a delay for DNS propagation
resource "null_resource" "dns_delay" {
  depends_on = [azurerm_dns_cname_record.azure_resource]

  provisioner "local-exec" {
    command = "sleep 600" # Waits for 10 minutes
  }
}

resource "azurerm_cdn_endpoint_custom_domain" "example" {
  depends_on      = [azurerm_cdn_endpoint.example, azurerm_dns_cname_record.azure_resource, null_resource.dns_delay,azurerm_dns_zone.panduhz_dns_zone]
  name            = "panduhzco-domain"
  cdn_endpoint_id = azurerm_cdn_endpoint.example.id
  host_name       = "www.panduhzco.com"

  cdn_managed_https {
    certificate_type = "Dedicated"
    protocol_type    = "ServerNameIndication"
    tls_version      = "TLS12"
  }
}
