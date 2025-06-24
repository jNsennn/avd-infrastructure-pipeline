# Azure authentication via environment variables (ARM_*)

# Resource Configuration
variable "resource_group_name" {
  description = "Name of the resource group for AVD resources"
  type        = string
  default     = "rg-avd"
}

variable "location" {
  description = "Azure region for resources"
  type        = string
  default     = "East US"
}

# Session Host Configuration (Microsoft pattern)
variable "rdsh_count" {
  description = "Number of AVD machines to deploy"
  type        = number
  default     = 1
}

variable "prefix" {
  type        = string
  default     = "avd"
  description = "Prefix of the name of the AVD machine(s)"
}

# VM Configuration
variable "vm_size" {
  description = "Size of the machine to deploy"
  type        = string
  default     = "Standard_B2s"
}

variable "admin_username" {
  type        = string
  default     = "avdadmin"
  description = "Local admin username"
}

variable "admin_password" {
  type        = string
  default     = ""
  description = "Local admin password (use TF_VAR_admin_password environment variable)"
  sensitive   = true
}

# Custom Image Configuration
variable "avd_image_name" {
  description = "Name of the custom AVD image to use (leave empty for latest)"
  type        = string
  default     = ""
}

variable "avd_image_resource_group" {
  description = "Resource group containing the AVD images"
  type        = string
  default     = "rg-packer-build"
}

# Update Control Variables
variable "force_recreate_session_hosts" {
  description = "Force recreation of all session hosts"
  type        = bool
  default     = false
}

variable "image_build_info" {
  description = "Information about the image build"
  type = object({
    build_date   = string
    build_number = string
    git_commit   = string
  })
  default = {
    build_date   = ""
    build_number = ""
    git_commit   = ""
  }
}

# Networking Configuration
variable "vnet_address_space" {
  description = "Address space for the virtual network"
  type        = list(string)
  default     = ["10.0.0.0/16"]
}

variable "subnet_address_prefix" {
  description = "Address prefix for the AVD subnet"
  type        = string
  default     = "10.0.1.0/24"
}

# Tags
variable "common_tags" {
  description = "Common tags to apply to all resources"
  type        = map(string)
  default = {
    Environment = "Learning"
    Project     = "AVD-DevOps"
    Purpose     = "Education"
    AutoDestroy = "true"
  }
}