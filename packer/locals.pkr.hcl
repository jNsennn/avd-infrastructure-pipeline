locals {
  # Timestamp for unique naming
  timestamp = regex_replace(timestamp(), "[- TZ:]", "")

  # Image naming convention
  image_name = "${var.managed_image_name}-${local.timestamp}"

  # Common tags
  common_tags = {
    Environment = "Production"
    Project     = "AVD"
    CreatedBy   = "Packer"
  }
}