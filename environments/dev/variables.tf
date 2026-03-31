variable "environment" {
  description = "Environment name"
  type        = string
  default     = "dev"
}

variable "location" {
  description = "Azure region for all resources"
  type        = string
  default     = "eastus"
}

variable "project" {
  description = "Project name used in resource naming"
  type        = string
  default     = "opella"
}

variable "vnet_address_space" {
  description = "Address space for the virtual network"
  type        = list(string)
  default     = ["10.0.0.0/16"]
}

variable "subnets" {
  description = "Subnet configurations for the dev environment"
  type = map(object({
    address_prefixes                      = list(string)
    service_endpoints                     = optional(list(string), [])
    private_endpoint_network_policies     = optional(string, "Enabled")
    private_link_service_network_policies = optional(bool, false)
  }))
  default = {
    "snet-app" = {
      address_prefixes  = ["10.0.1.0/24"]
      service_endpoints = ["Microsoft.Storage"]
    }
    "snet-data" = {
      address_prefixes  = ["10.0.2.0/24"]
      service_endpoints = ["Microsoft.Storage"]
    }
  }
}

variable "vm_size" {
  description = "Size of the virtual machine"
  type        = string
  default     = "Standard_B1s"
}

variable "vm_admin_username" {
  description = "Admin username for the virtual machine"
  type        = string
  default     = "azureadmin"
}

variable "vm_ssh_public_key" {
  description = "SSH public key for VM authentication"
  type        = string
  sensitive   = true
}
