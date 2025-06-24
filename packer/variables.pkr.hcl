variable "subscription_id" {
  type        = string
  description = "Azure subscription ID"
}

variable "tenant_id" {
  type        = string
  description = "Azure tenant ID"
}

variable "client_id" {
  type        = string
  description = "Azure client ID"
}

variable "client_secret" {
  type        = string
  description = "Azure client secret"
  sensitive   = true
}

variable "resource_group_name" {
  type        = string
  description = "Name of the resource group"
}

variable "location" {
  type        = string
  description = "Azure region"
  default     = "East US"
}

variable "vm_size" {
  type        = string
  description = "Size of the VM (using smallest for cost savings)"
  default     = "Standard_D2s_v5"
}

variable "image_publisher" {
  type        = string
  description = "Image publisher"
  default     = "MicrosoftWindowsDesktop"
}

variable "image_offer" {
  type        = string
  description = "Image offer (Windows 11 with AVD optimizations)"
  default     = "Windows-11"
}

variable "image_sku" {
  type        = string
  description = "Image SKU (multi-session for cost efficiency)"
  default     = "win11-23h2-avd"
}

variable "image_version" {
  type        = string
  description = "Image version"
  default     = "latest"
}

variable "managed_image_name" {
  type        = string
  description = "Name of the managed image"
}

variable "base_image_name" {
  type        = string
  description = "Name of the base image to update from"
  default     = ""
}