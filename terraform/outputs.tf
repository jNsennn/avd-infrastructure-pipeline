# outputs.tf - Enhanced for AVD Host Pool Updates

output "resource_group_name" {
  description = "Name of the resource group"
  value       = azurerm_resource_group.avd.name
}

output "host_pool_name" {
  description = "Name of the AVD host pool"
  value       = azurerm_virtual_desktop_host_pool.main.name
}

output "workspace_name" {
  description = "Name of the AVD workspace"
  value       = azurerm_virtual_desktop_workspace.main.name
}

output "session_host_count" {
  description = "The number of VMs created"
  value       = var.rdsh_count
}

output "session_host_names" {
  description = "Names of the session host VMs"
  value       = azurerm_windows_virtual_machine.avd_vm[*].name
}

output "session_host_private_ips" {
  description = "Private IPs of the session hosts"
  value       = azurerm_network_interface.avd_vm_nic[*].private_ip_address
}

output "avd_workspace_url" {
  description = "URL to access the AVD workspace"
  value       = "https://rdweb.wvd.microsoft.com/arm/webclient/index.html"
}

output "allowed_source_ip" {
  description = "IP address allowed for RDP access"
  value       = local.current_ip
}

output "connection_info" {
  description = "Connection information"
  value = {
    workspace_url     = "https://rdweb.wvd.microsoft.com/arm/webclient/index.html"
    host_pool         = azurerm_virtual_desktop_host_pool.main.name
    workspace         = azurerm_virtual_desktop_workspace.main.name
    session_hosts     = azurerm_windows_virtual_machine.avd_vm[*].name
    user_email       = "user@yourdomain.com"
    next_step        = "Run the post_deployment_commands to assign user permissions"
  }
}

output "post_deployment_commands" {
  description = "Commands to run after deployment (replace USER_EMAIL with actual email)"
  value = <<-EOT
    # Step 1: Get user object ID
    USER_EMAIL="user@yourdomain.com"
    USER_ID=$(az ad user show --id "$USER_EMAIL" --query "id" --output tsv)
    
    # Step 2: Assign user to Desktop Application Group
    az role assignment create \
      --assignee "$USER_ID" \
      --role "Desktop Virtualization User" \
      --scope "${azurerm_virtual_desktop_application_group.desktop.id}"
    
    # Step 3: Assign VM User Login role  
    az role assignment create \
      --assignee "$USER_ID" \
      --role "Virtual Machine User Login" \
      --scope "${azurerm_resource_group.avd.id}"
    
    # Step 4: Test connection
    echo "Access AVD at: https://rdweb.wvd.microsoft.com/arm/webclient/index.html"
    echo "Sign in with: $USER_EMAIL"
  EOT
}

# Enhanced debugging outputs for image management
output "image_selection_debug" {
  description = "Debug info for image selection"
  value = {
    use_latest_image     = local.use_latest_image
    all_avd_images      = try(local.avd_images_filtered[*].name, [])
    sorted_images       = try(local.sorted_image_names, [])
    selected_image      = local.selected_image_name
    selected_image_id   = local.selected_image_id
    force_recreate      = var.force_recreate_session_hosts
  }
}

output "current_image_info" {
  description = "Information about currently used image"
  value = {
    image_name = local.selected_image_name
    image_id   = local.selected_image_id
    source     = local.selected_image_id != null ? "custom" : "marketplace"
    build_info = var.image_build_info
  }
}

output "session_host_tags" {
  description = "Tags applied to session hosts for tracking"
  value = {
    for idx in range(var.rdsh_count) : 
    azurerm_windows_virtual_machine.avd_vm[idx].name => {
      ImageName    = local.selected_image_name != "" ? local.selected_image_name : "marketplace"
      ImageId      = local.selected_image_id != null ? local.selected_image_id : "marketplace"
      BuildDate    = var.image_build_info.build_date
      BuildNumber  = var.image_build_info.build_number
      GitCommit    = var.image_build_info.git_commit
      LastUpdated  = azurerm_windows_virtual_machine.avd_vm[idx].tags["LastUpdated"]
    }
  }
}