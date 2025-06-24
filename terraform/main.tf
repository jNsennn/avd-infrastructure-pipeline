# main.tf - Complete AVD with Session Host using Custom Image (Microsoft Pattern)

# Configure the Azure Provider
terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~>3.0"
    }
    azuread = {
      source = "hashicorp/azuread"
      version = "~>2.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~>3.1"
    }
    http = {
      source  = "hashicorp/http"
      version = "~>3.0"
    }
  }
}

provider "azurerm" {
  features {}
}

# Get current public IP automatically
data "http" "current_ip" {
  url = "https://ipv4.icanhazip.com"
}

# Generate random password if not provided
resource "random_password" "vm_password" {
  count   = var.admin_password == "" ? 1 : 0
  length  = 16
  special = true
  min_special = 2
  override_special = "*!@#?"
}

locals {
  # Use provided password or generate one
  admin_password = var.admin_password != "" ? var.admin_password : random_password.vm_password[0].result
  
  # Get current IP and remove any whitespace
  current_ip = chomp(data.http.current_ip.response_body)
  
  # Find latest image if none specified
  use_latest_image = var.avd_image_name == ""
  
  # Registration token for AVD agent
  registration_token = azurerm_virtual_desktop_host_pool_registration_info.main.token
}

# Data source to find all custom images
data "azurerm_images" "avd_images" {
  count               = local.use_latest_image ? 1 : 0
  resource_group_name = var.avd_image_resource_group
}

# Data source for specific image
data "azurerm_image" "specific_image" {
  count               = local.use_latest_image ? 0 : 1
  name                = var.avd_image_name
  resource_group_name = var.avd_image_resource_group
}

locals {
  # Select the image to use - filter for AVD images and get the LATEST by name
  avd_images_filtered = local.use_latest_image ? [
    for image in data.azurerm_images.avd_images[0].images : image 
    if length(regexall("^avd-win11-", image.name)) > 0
  ] : []
  
  # Sort image names (since format is avd-win11-YYYY-MM-DD-HHMMSS, alphabetical sort = date sort)
  sorted_image_names = local.use_latest_image ? reverse(sort([
    for image in local.avd_images_filtered : image.name
  ])) : []
  
  # Get the latest image name (first in reversed sorted list)
  latest_image_name = local.use_latest_image && length(local.sorted_image_names) > 0 ? local.sorted_image_names[0] : ""
  
  selected_image_id = local.use_latest_image ? (
    local.latest_image_name != "" ? 
    "/subscriptions/${data.azurerm_client_config.current.subscription_id}/resourceGroups/${var.avd_image_resource_group}/providers/Microsoft.Compute/images/${local.latest_image_name}" : 
    null
  ) : data.azurerm_image.specific_image[0].id
  
  # Extract image name for tagging
  selected_image_name = local.use_latest_image ? local.latest_image_name : var.avd_image_name
}

# Get current Azure client configuration
data "azurerm_client_config" "current" {}

# Resource Group for AVD resources
resource "azurerm_resource_group" "avd" {
  name     = var.resource_group_name
  location = var.location
  tags     = var.common_tags
}

# Virtual Network
resource "azurerm_virtual_network" "avd_vnet" {
  name                = "vnet-avd"
  address_space       = var.vnet_address_space
  location            = azurerm_resource_group.avd.location
  resource_group_name = azurerm_resource_group.avd.name
  tags                = var.common_tags
}

# Subnet for AVD
resource "azurerm_subnet" "avd_subnet" {
  name                 = "subnet-avd"
  resource_group_name  = azurerm_resource_group.avd.name
  virtual_network_name = azurerm_virtual_network.avd_vnet.name
  address_prefixes     = [var.subnet_address_prefix]
}

# Network Security Group with restricted access
resource "azurerm_network_security_group" "avd_nsg" {
  name                = "nsg-avd"
  location            = azurerm_resource_group.avd.location
  resource_group_name = azurerm_resource_group.avd.name
  tags                = var.common_tags

  # Allow RDP only from your current IP
  security_rule {
    name                       = "AllowRDPFromMyIP"
    priority                   = 1001
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "3389"
    source_address_prefix      = "${local.current_ip}/32"
    destination_address_prefix = "*"
  }

  # Allow AVD agent traffic
  security_rule {
    name                       = "AllowAVDAgent"
    priority                   = 1002
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_ranges    = ["80", "443"]
    source_address_prefix      = "WindowsVirtualDesktop"
    destination_address_prefix = "*"
  }
}

# Associate NSG with subnet
resource "azurerm_subnet_network_security_group_association" "avd_nsg_association" {
  subnet_id                 = azurerm_subnet.avd_subnet.id
  network_security_group_id = azurerm_network_security_group.avd_nsg.id
}

# Create AVD workspace
resource "azurerm_virtual_desktop_workspace" "main" {
  name                = "ws-avd"
  location            = azurerm_resource_group.avd.location
  resource_group_name = azurerm_resource_group.avd.name
  friendly_name       = "AVD Learning Workspace"
  description         = "Workspace for AVD Learning Environment"
  tags                = var.common_tags
}

# Create AVD host pool
resource "azurerm_virtual_desktop_host_pool" "main" {
  name                = "hp-avd"
  location            = azurerm_resource_group.avd.location
  resource_group_name = azurerm_resource_group.avd.name
  
  type                     = "Pooled"
  load_balancer_type       = "DepthFirst"  # Microsoft uses DepthFirst
  maximum_sessions_allowed = 16           # Microsoft uses 16
  validate_environment     = true         # Microsoft recommendation
  
  # Microsoft's RDP properties for Azure AD joined VMs
  custom_rdp_properties = "audiocapturemode:i:1;audiomode:i:0;enablecredsspsupport:i:1;targetisaadjoined:i:1"
  
  description = "AVD Learning HostPool"
  tags        = var.common_tags
}

# Registration token for host pool
resource "azurerm_virtual_desktop_host_pool_registration_info" "main" {
  hostpool_id     = azurerm_virtual_desktop_host_pool.main.id
  expiration_date = timeadd(timestamp(), "24h")
}

# Create AVD Desktop Application Group
resource "azurerm_virtual_desktop_application_group" "desktop" {
  name                = "dag-desktop"
  location            = azurerm_resource_group.avd.location
  resource_group_name = azurerm_resource_group.avd.name
  
  type          = "Desktop"
  host_pool_id  = azurerm_virtual_desktop_host_pool.main.id
  friendly_name = "Learning Desktop"
  description   = "Desktop Application Group for AVD Learning"
  
  tags = var.common_tags
  
  depends_on = [
    azurerm_virtual_desktop_host_pool.main,
    azurerm_virtual_desktop_workspace.main
  ]
}

# Associate Workspace and Desktop Application Group
resource "azurerm_virtual_desktop_workspace_application_group_association" "main" {
  workspace_id         = azurerm_virtual_desktop_workspace.main.id
  application_group_id = azurerm_virtual_desktop_application_group.desktop.id
}

# Network Interface for Session Host (Microsoft pattern with count)
resource "azurerm_network_interface" "avd_vm_nic" {
  count               = var.rdsh_count
  name                = "${var.prefix}-${count.index + 1}-nic"
  resource_group_name = azurerm_resource_group.avd.name
  location            = azurerm_resource_group.avd.location
  tags                = var.common_tags

  ip_configuration {
    name                          = "nic${count.index + 1}_config"
    subnet_id                     = azurerm_subnet.avd_subnet.id
    private_ip_address_allocation = "Dynamic"
  }
  
  depends_on = [
    azurerm_resource_group.avd
  ]
}

# Session Host Virtual Machine with update capabilities
resource "azurerm_windows_virtual_machine" "avd_vm" {
  count               = var.rdsh_count
  name                = "${var.prefix}-${count.index + 1}"
  resource_group_name = azurerm_resource_group.avd.name
  location            = azurerm_resource_group.avd.location
  size                = var.vm_size
  admin_username      = var.admin_username
  admin_password      = local.admin_password
  provision_vm_agent  = true  # Microsoft includes this
  
  network_interface_ids = [azurerm_network_interface.avd_vm_nic[count.index].id]
  
  tags = merge(var.common_tags, {
    Role = "SessionHost"
    AutoShutdown = "19:00"
    ImageName = local.selected_image_name != "" ? local.selected_image_name : "marketplace"
    ImageId = local.selected_image_id != null ? local.selected_image_id : "marketplace"
    BuildDate = var.image_build_info.build_date
    BuildNumber = var.image_build_info.build_number
    GitCommit = var.image_build_info.git_commit
    LastUpdated = timestamp()
  })

  os_disk {
    name                 = "${lower(var.prefix)}-${count.index + 1}"
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"  # Microsoft uses Standard_LRS
  }

  # Use custom image if available, otherwise marketplace image
  dynamic "source_image_reference" {
    for_each = local.selected_image_id == null ? [1] : []
    content {
      publisher = "MicrosoftWindowsDesktop"
      offer     = "Windows-11"
      sku       = "win11-23h2-avd"
      version   = "latest"
    }
  }

  # Use custom image
  source_image_id = local.selected_image_id

  # Enable system-assigned managed identity for Azure AD join
  identity {
    type = "SystemAssigned"
  }

  # Force recreation through external means (GitHub Actions will handle this)
  lifecycle {
    create_before_destroy = true
  }

  depends_on = [
    azurerm_resource_group.avd,
    azurerm_network_interface.avd_vm_nic
  ]
}

# Azure AD Join Extension - Install FIRST
resource "azurerm_virtual_machine_extension" "azure_ad_join" {
  count                      = var.rdsh_count
  name                       = "${var.prefix}${count.index + 1}-aad-join"
  virtual_machine_id         = azurerm_windows_virtual_machine.avd_vm[count.index].id
  publisher                  = "Microsoft.Azure.ActiveDirectory"
  type                       = "AADLoginForWindows"
  type_handler_version       = "1.0"
  auto_upgrade_minor_version = true

  depends_on = [
    azurerm_windows_virtual_machine.avd_vm
  ]
}

# Install AVD Agent using PowerShell DSC Extension (Microsoft pattern)
resource "azurerm_virtual_machine_extension" "vmext_dsc" {
  count                = var.rdsh_count
  name                 = "${var.prefix}${count.index + 1}-avd_dsc"
  virtual_machine_id   = azurerm_windows_virtual_machine.avd_vm[count.index].id
  publisher            = "Microsoft.Powershell"
  type                 = "DSC"
  type_handler_version = "2.73"
  auto_upgrade_minor_version = true
  
  settings = <<-SETTINGS
    {
        "modulesUrl": "https://wvdportalstorageblob.blob.core.windows.net/galleryartifacts/Configuration_09-08-2022.zip",
        "configurationFunction": "Configuration.ps1\\AddSessionHost",
        "properties": {
            "HostPoolName": "${azurerm_virtual_desktop_host_pool.main.name}",
            "aadJoin": true
        }
    }
SETTINGS

  protected_settings = <<PROTECTED_SETTINGS
    {
        "properties": {
            "registrationInfoToken": "${local.registration_token}"
        }
    }
PROTECTED_SETTINGS
  
  depends_on = [
    azurerm_virtual_desktop_host_pool.main,
    azurerm_windows_virtual_machine.avd_vm,
    azurerm_virtual_machine_extension.azure_ad_join
  ]
}

# Auto-shutdown schedule for cost savings
resource "azurerm_dev_test_global_vm_shutdown_schedule" "session_host" {
  count              = var.rdsh_count
  virtual_machine_id = azurerm_windows_virtual_machine.avd_vm[count.index].id
  location           = azurerm_resource_group.avd.location
  enabled            = true

  daily_recurrence_time = "1900"  # 7 PM
  timezone              = "Central European Standard Time"

  notification_settings {
    enabled = false
  }

  tags = var.common_tags
}

# Note: User assignments will be done manually after deployment
# This avoids permission issues with the service principal