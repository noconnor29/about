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
  name                = "site_about_noconnor_io"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  repository_url      = var.github_repository
  # need to configure secrets in GH/TFC
  app_settings = {
    "GITHUB_TOKEN" = ""
  }
}

# Create a DNS record for the site
resource "cloudflare_record" "dns_about_noconnor_io" {
  name     = var.subdomain
  priority = 10
  proxied  = false
  ttl      = var.ttl
  type     = "CNAME"
  value    = azurerm_static_site.static_site.default_hostname
  #value    = "ambitious-stone-01b1b0c0f.3.azurestaticapps.net"
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
  value = azurerm_static_site.static_site.default_hostname
}

# Create CosmosDB to track site visits
resource "azurerm_cosmosdb_account" "cdb" {
  name                = "cdb-resume-dev"
  location            = "eastus2"
  resource_group_name = "rg-resume-dev"
  offer_type          = "Standard"
  kind                = "GlobalDocumentDB"

  enable_automatic_failover           = true
  enable_multiple_write_locations     = true
  is_virtual_network_filter_enabled   = false
  enable_automatic_backup             = true
  backup_interval_in_minutes          = 1440
  backup_retention_in_hours           = 48
  enable_zone_redundant_storage       = true
  enable_public_network_access        = true
  enable_virtual_network_integration = false

  capabilities {
    name = "EnableServerless"
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

  default_ttl { # documents do not expire
    seconds = -1
  }

  cors_rule {
    allowed_origins     = ["https://example.com"]
    allowed_methods    = ["GET", "POST"]
    allowed_headers    = ["*"]
    exposed_headers    = ["*"]
    max_age_in_seconds = 86400
  }
}

# Output the endpoint URL of the CDB
output "endpoint" {
  value = azurerm_cosmosdb_account.cdb.document_endpoint
}

# ghost edit