environment = "dev"
location    = "eastus"
project     = "opella"

vnet_address_space = ["10.0.0.0/16"]

subnets = {
  "snet-app" = {
    address_prefixes  = ["10.0.1.0/24"]
    service_endpoints = ["Microsoft.Storage"]
  }
  "snet-data" = {
    address_prefixes  = ["10.0.2.0/24"]
    service_endpoints = ["Microsoft.Storage"]
  }
}
