terraform {
  backend "azurerm" {
    resource_group_name  = "rg-terraform-state"
    storage_account_name = "tfstate1750583704"  # Replace with your actual storage account name
    container_name       = "tfstate"
    key                  = "avd.tfstate"
  }
}