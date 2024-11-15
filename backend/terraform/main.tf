terraform {
  cloud {
    hostname     = "app.terraform.io"
    organization = "NODV"

    workspaces {
      tags = ["cloud-resume"]
    }
  }

  required_providers {
    azapi = {
      source  = "azure/azapi"
      version = "~> 1.0"
    }

    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">= 2.0"
    }

    cloudflare = {
      source  = "cloudflare/cloudflare"
      version = "~> 3.0"
    }

    github = {
      source  = "integrations/github"
      version = "~> 5.0"
    }

    http-full = {
      source  = "salrashid123/http-full"
      version = "1.3.1"
    }
  }
}

provider "azapi" {
  subscription_id = var.azure_subscription_id
  tenant_id       = var.azure_subscription_tenant_id
  client_id       = var.service_principal_appid
  client_secret   = var.service_principal_password
}

provider "azurerm" {
  features {
    resource_group {
      prevent_deletion_if_contains_resources = false
    }
  }
  skip_provider_registration = true

  # https://learn.microsoft.com/en-us/azure/developer/terraform/authenticate-to-azure?tabs=bash
  subscription_id = var.azure_subscription_id
  tenant_id       = var.azure_subscription_tenant_id
  client_id       = var.service_principal_appid
  client_secret   = var.service_principal_password
}

provider "cloudflare" {
  api_token = var.cloudflare_api_token
}

provider "github" {
  token = var.github_token
}

## Define locals
locals {
  github_repo_name  = basename(var.github_repo_url)
  github_action_url = "https://api.github.com/repos/${var.github_owner}/${local.github_repo_name}/actions/workflows/${var.github_workflow_webapp}/dispatches"
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

  #identity {
  #  type         = SystemAssigned
  #   identity_ids = [var.service_principal_appid]
  #}

  #staging_environment_policy = "Enabled"
  #allow_config_file_updates  = true
  #provider                   = "GitHub"
  #enterprise_grade_cdn_status = "Disabled"
}

resource "github_actions_secret" "static_site_token" {
  repository      = local.github_repo_name
  secret_name     = "AZURE_STATIC_WEB_APPS_API_TOKEN"
  plaintext_value = azurerm_static_site.static_site.api_key
}

resource "azapi_update_resource" "configure_static_site" {
  type        = "Microsoft.Web/staticSites@2022-03-01"
  resource_id = azurerm_static_site.static_site.id
  body = jsonencode({
    properties = {
      # this branch should be a variable by environment
      branch = "main"
      buildProperties = {
        apiLocation                        = "/backend/api"
        appLocation                        = "/frontend"
        githubActionSecretNameOverride     = "AZURE_STATIC_WEB_APPS_API_TOKEN"
        skipGithubActionWorkflowGeneration = true
      }
      customDomains = [
        "${var.subdomain}.${var.domain}"
      ]
      repositoryUrl = var.github_repo_url
    }
  })
  depends_on = [github_actions_secret.static_site_token]
}

# Trigger the GitHub Action to build the site
resource "null_resource" "trigger_gh_action" {
  triggers = {
    always_run = timestamp()
  }

  provisioner "local-exec" {
    command = <<EOF
    curl -X POST \
      -H "Accept: application/vnd.github+json" \
      -H "X-GitHub-Api-Version: 2022-11-28" \
      -H "Authorization: Bearer ${var.github_token}" \
      -d '{"ref":"main","inputs":{}}' \
      ${local.github_action_url}
    EOF
  }

  depends_on = [azapi_update_resource.configure_static_site]
}

# Create a DNS record for the site
resource "cloudflare_record" "dns_about_noconnor_io" {
  name       = var.subdomain
  priority   = 10
  proxied    = false
  ttl        = var.ttl
  type       = "CNAME"
  value      = azurerm_static_site.static_site.default_host_name
  zone_id    = var.cloudflare_zone_id
  depends_on = [azurerm_static_site.static_site]
}

resource "azurerm_static_site_custom_domain" "azure_static_site" {
  static_site_id  = azurerm_static_site.static_site.id
  domain_name     = "${var.subdomain}.${var.domain}"
  validation_type = "cname-delegation"
  depends_on      = [cloudflare_record.dns_about_noconnor_io]
}

# Output the static site endpoint
output "static_site_endpoint" {
  value = azurerm_static_site.static_site.default_host_name
}

# Create CosmosDB to track site visits
resource "azurerm_cosmosdb_account" "cdb" {
  name                = var.cosmosdb_name
  location            = azurerm_resource_group.rg.location
  resource_group_name = var.resource_group_name
  offer_type          = "Standard"
  kind                = "GlobalDocumentDB"
  backup {
    type                = "Periodic"
    interval_in_minutes = 1440
    retention_in_hours  = 48
    storage_redundancy  = "Zone"
  }
  geo_location {
    location          = azurerm_resource_group.rg.location
    failover_priority = 0
    zone_redundant    = false
  }
  consistency_policy {
    consistency_level = "Eventual"
  }
  enable_automatic_failover         = true
  enable_multiple_write_locations   = false
  is_virtual_network_filter_enabled = false
  public_network_access_enabled     = true

  capabilities {
    name = "EnableServerless"
  }
  #cors_rule {
  #allowed_origins    = ["https://about.noconnor.io"]
  #allowed_methods    = ["GET", "POST"]
  #allowed_headers    = ["*"]
  #exposed_headers    = ["*"]
  #max_age_in_seconds = 86400
  #}
}

resource "azurerm_cosmosdb_sql_database" "db" {
  name                = "db"
  resource_group_name = var.resource_group_name
  account_name        = azurerm_cosmosdb_account.cdb.name
}

resource "azurerm_cosmosdb_sql_container" "container" {
  name                = "visitorCount"
  resource_group_name = var.resource_group_name
  account_name        = azurerm_cosmosdb_account.cdb.name
  database_name       = azurerm_cosmosdb_sql_database.db.name
  partition_key_path  = "/id"
  default_ttl         = -1
}

# Output the endpoint URL of the CDB
output "endpoint" {
  value = azurerm_cosmosdb_account.cdb.endpoint
}