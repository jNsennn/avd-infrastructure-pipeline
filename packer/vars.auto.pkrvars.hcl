#subscription_id = "your-subscription-id" 
#For local use, use PKR_VAR_subscription_id="your-subscription-id". For Github Actions, add as a secret

#tenant_id       = "your-tenant-id" 
#For local use, use PKR_VAR_tenant_id ="your-tenant-id". For Github Actions, add as a secret

#client_id       = "your-client-id"
#For local use, use PKR_VAR_client_id ="your-client-id". For Github Actions, add as a secret


# client_secret should be set via environment variable: export PKR_VAR_client_secret="your-secret". For Github Actions, add as a secret

#resource_group_name = "your-resource-group-name"
#For local use, use PKR_VAR_resource_group_name ="your-resource-group-name". For Github Actions, add as a secret

location            = "East US"
vm_size             = "Standard_D2s_v3"

image_publisher = "MicrosoftWindowsDesktop"
image_offer     = "Windows-11"
image_sku       = "win11-23h2-avd" # Latest Windows 11 with AVD optimizations
image_version   = "latest"

managed_image_name = "avd-win11-manual-build"