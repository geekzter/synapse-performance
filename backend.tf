# See https://www.terraform.io/docs/backends/types/azurerm.html

terraform {
  backend "azurerm" {
    resource_group_name        = "automation"
    storage_account_name       = "ewterraformstate"
    container_name             = "awsvpn" 
    key                        = "terraform.tfstate"
  }
}