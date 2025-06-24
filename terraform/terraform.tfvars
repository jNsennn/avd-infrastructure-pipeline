# Azure authentication via environment variables (ARM_*)
# Set these before running terraform:
# export ARM_SUBSCRIPTION_ID="your-subscription-id"
# export ARM_TENANT_ID="your-tenant-id"
# export ARM_CLIENT_ID="your-client-id"
# export ARM_CLIENT_SECRET="your-client-secret"
# export TF_VAR_admin_password="YourSecurePassword123!"

# Resource Configuration
resource_group_name = "rg-avd"
location           = "East US"

# Session Host Configuration (Microsoft pattern)
rdsh_count = 2
prefix     = "avd"

# VM Configuration
vm_size        = "Standard_B2ms"
admin_username = "avdadmin"
# admin_password will be set via environment variable TF_VAR_admin_password

# Custom Image Configuration
avd_image_name              = ""  # Leave empty to use latest image automatically
avd_image_resource_group    = "rg-packer-build"

# Networking Configuration
vnet_address_space     = ["10.0.0.0/16"]
subnet_address_prefix  = "10.0.1.0/24"

# Tags
common_tags = {
  Environment = "Learning"
  Project     = "AVD-DevOps"
  Purpose     = "Education"
  AutoDestroy = "true"
}