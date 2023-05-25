terraform {
  cloud {
    hostname     = "app.terraform.io"
    organization = "NODV"

    workspaces {
      name = "cloud-resume"
    }
  }

  required_providers {
    cloudflare = {
      source  = "cloudflare/cloudflare"
      version = "~> 3.0"
    }
  }
}

provider "azurerm" {
  features {}
}

provider "azapi" {
  source  = "azure/azapi"
  version = "~> 1.0"
}

provider "cloudflare" {
}

## Create resources
# Create resource group
resource "azurerm_resource_group" "rg" {
  name     = var.resource_group_name
  location = var.az_region
}

# Create Azure Static Web App
resource "azurerm_static_site" "static_site" {
  name                = "site-about-noconnor-io"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  sku_tier            = "Free"
  sku_size            = "Free"

  #staging_environment_policy = "Enabled"
  #allow_config_file_updates  = true
  #provider                   = "GitHub"
  #enterprise_grade_cdn_status = "Disabled"
}

resource "azapi_update_resource" "configure_static_site" {
  type        = "Microsoft.Web/staticSites@2022-03-01"
  resource_id = azurerm_static_site.static_site.id
  body = jsonencode({
    properties = {
      customDomains = [
        "${var.subdomain}.${var.domain}"
      ]
      repositoryUrl = "https://github.com/noconnor29/resume"
      branch        = "main"
    }
  })
}

# Create a DNS record for the site
resource "cloudflare_record" "dns_about_noconnor_io" {
  name       = var.subdomain
  priority   = 10
  proxied    = false
  ttl        = var.ttl
  type       = "CNAME"
  value      = azurerm_static_site.static_site.default_host_name
  zone_id    = "695e898dffb5370b3e32e67bb903272e"
  depends_on = [azurerm_static_site.static_site]
}

resource "azurerm_static_site_custom_domain" "example" {
  static_site_id  = azurerm_static_site.static_site.id
  domain_name     = "${var.subdomain}.${var.domain}"
  validation_type = "cname-delegation"
}

# Output the static site endpoint
output "static_site_endpoint" {
  value = azurerm_static_site.static_site.default_host_name
}

# Create CosmosDB to track site visits
resource "azurerm_cosmosdb_account" "cdb" {
  name                = "cdb-resume-dev"
  location            = "eastus2"
  resource_group_name = "rg-resume-dev"
  offer_type          = "Standard"
  kind                = "GlobalDocumentDB"
  backup {
    type                = "Periodic"
    interval_in_minutes = 1440
    retention_in_hours  = 48
    storage_redundancy  = "Zone"
  }
  geo_location {
    location          = "eastus2"
    failover_priority = 0
    zone_redundant    = true
  }
  consistency_policy {
    consistency_level = "Eventual"
  }
  enable_automatic_failover         = true
  enable_multiple_write_locations   = true
  is_virtual_network_filter_enabled = false
  public_network_access_enabled     = true

  capabilities {
    name = "EnableServerless"
  }
  cors_rule {
    allowed_origins    = ["https://example.com"]
    allowed_methods    = ["GET", "POST"]
    allowed_headers    = ["*"]
    exposed_headers    = ["*"]
    max_age_in_seconds = 86400
  }
}

resource "azurerm_cosmosdb_sql_database" "db" {
  name                = "db"
  resource_group_name = "rg-resume-dev"
  account_name        = azurerm_cosmosdb_account.cdb.name
}

resource "azurerm_cosmosdb_sql_container" "container" {
  name                = "visitorCount"
  resource_group_name = "rg-resume-dev"
  account_name        = azurerm_cosmosdb_account.cdb.name
  database_name       = azurerm_cosmosdb_sql_database.db.name
  partition_key_path  = "/id"
  throughput          = 400
  default_ttl         = -1
}

# Output the endpoint URL of the CDB
output "endpoint" {
  value = azurerm_cosmosdb_account.cdb.endpoint
}