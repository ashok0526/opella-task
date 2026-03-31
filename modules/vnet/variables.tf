variable "vnet_name" {
  description = "Name of the Virtual Network"
  type        = string
}

variable "resource_group_name" {
  description = "Name of the resource group where the VNET will be created"
  type        = string
}

variable "location" {
  description = "Azure region for the VNET"
  type        = string
}

variable "address_space" {
  description = "Address space for the VNET in CIDR notation"
  type        = list(string)
  default     = ["10.0.0.0/16"]
}

variable "dns_servers" {
  description = "Custom DNS servers for the VNET. Uses Azure-provided DNS if empty."
  type        = list(string)
  default     = []
}

variable "subnets" {
  description = "Map of subnet configurations to create within the VNET"
  type = map(object({
    address_prefixes                      = list(string)
    service_endpoints                     = optional(list(string), [])
    private_endpoint_network_policies     = optional(string, "Enabled")
    private_link_service_network_policies = optional(bool, false)
  }))
  default = {}
}

variable "nsg_rules" {
  description = "Map of NSG rules to apply to subnets. Key should match a subnet name."
  type = map(list(object({
    name                       = string
    priority                   = number
    direction                  = string
    access                     = string
    protocol                   = string
    source_port_range          = optional(string, "*")
    destination_port_range     = optional(string, "*")
    source_address_prefix      = optional(string, "*")
    destination_address_prefix = optional(string, "*")
  })))
  default = {}
}

variable "enable_ddos_protection" {
  description = "Enable Azure DDoS Protection Plan for the VNET"
  type        = bool
  default     = false
}

variable "tags" {
  description = "Tags to apply to all resources created by this module"
  type        = map(string)
  default     = {}
}
