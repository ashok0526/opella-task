locals {
  name_prefix = "${var.project}-${var.environment}-${var.location}"

  common_tags = {
    Environment = var.environment
    Project     = var.project
    Region      = var.location
    ManagedBy   = "terraform"
  }
}
