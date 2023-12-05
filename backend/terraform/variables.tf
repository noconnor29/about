variable "domain" {
  type = string
}

variable "subdomain" {
  type = string
}

variable "cloudflare_zone_id" {
  type = string
}

variable "ttl" {
  type        = number
  default     = 3600
  description = "TTL of DNS record in seconds"
  validation {
    condition     = contains([60, 120, 300, 600, 900, 1800, 3600, 7200, 18000, 43200, 86400], var.ttl)
    error_message = "Valid values for var: ttl are 60, 120, 300, 600, 900, 1800, 3600, 7200 18000, 43200, 86400."
  }
}

variable "resource_group_name" {
  description = "Name of the Azure resource group"
  type        = string
}

variable "az_region" {
  description = "Azure region where resources will be deployed"
  type        = string
}

variable "github_repo_url" {
  description = "URL of the GitHub repository to deploy"
  type        = string
}

variable "github_token" {
  description = "Token allowing updates to the GitHub repository"
  type        = string
}

variable "github_owner" {
  description = "Owner of the GitHub repository to deploy"
  type        = string
}

variable "github_workflow_webapp" {
  description = "Name of GitHub Actions workflow to deploy Web App content"
  type        = string
}


variable "cloudflare_api_token" {
  description = "API token for Cloudflare authentication"
  type        = string
  sensitive   = true
}

variable "azure_subscription_id" {
  description = "Azure Subscription ID"
  type        = string
  sensitive   = false
}

variable "azure_subscription_tenant_id" {
  description = "Azure Subscription Tenant ID"
  type        = string
  sensitive   = false
}

variable "service_principal_appid" {
  description = "Service Principal AppID"
  type        = string
  sensitive   = false
}

variable "service_principal_password" {
  description = "Service Principal Password"
  type        = string
  sensitive   = true
}

variable "cosmosdb_name" {
  description = "Name of the CosmosDB instance"
  type        = string
}