# Source for updating existing custom images
source "azure-arm" "update" {
  # Azure authentication
  subscription_id = var.subscription_id
  tenant_id       = var.tenant_id
  client_id       = var.client_id
  client_secret   = var.client_secret

  # Use existing custom image as base - will be set dynamically by workflow
  custom_managed_image_name                = var.base_image_name
  custom_managed_image_resource_group_name = var.resource_group_name

  # New image configuration
  managed_image_resource_group_name = var.resource_group_name
  managed_image_name                = var.managed_image_name
  location                          = var.location

  # VM configuration
  vm_size = var.vm_size

  # OS configuration
  os_type        = "Windows"
  communicator   = "winrm"
  winrm_use_ssl  = true
  winrm_insecure = true
  winrm_timeout  = "10m"
  winrm_username = "packer"

  # Build configuration
  async_resourcegroup_delete = true

  # Tags
  azure_tags = local.common_tags
}

# Source for building from marketplace image (first time)
source "azure-arm" "avd-image" {
  # Azure authentication
  subscription_id = var.subscription_id
  tenant_id       = var.tenant_id
  client_id       = var.client_id
  client_secret   = var.client_secret

  # Resource configuration
  managed_image_resource_group_name = var.resource_group_name
  managed_image_name                = var.managed_image_name
  location                          = var.location

  # VM configuration
  vm_size = var.vm_size

  # Source image
  image_publisher = var.image_publisher
  image_offer     = var.image_offer
  image_sku       = var.image_sku
  image_version   = var.image_version

  # OS configuration
  os_type        = "Windows"
  communicator   = "winrm"
  winrm_use_ssl  = true
  winrm_insecure = true
  winrm_timeout  = "10m"
  winrm_username = "packer"

  # Build configuration
  async_resourcegroup_delete = true

  # Tags
  azure_tags = local.common_tags
}