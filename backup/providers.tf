terraform {
  required_version = ">= 1.0.0"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">= 2.0"
    }
  }
}

# Provider to work with the Data Eng'g subscription

provider "azurerm" { 
  alias = "<Subscription_Name>"
  tenant_id = "<tenant_ID>"
  subscription_id = "<Subscription_ID>"
  features {
    resource_group {
      prevent_deletion_if_contains_resources = true
    }
  }
}
