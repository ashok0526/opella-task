environment = "prod"
location    = "westus2"
project     = "opella"

vnet_address_space = ["10.1.0.0/16"]

subnets = {
  "snet-app" = {
    address_prefixes  = ["10.1.1.0/24"]
    service_endpoints = ["Microsoft.Storage"]
  }
  "snet-data" = {
    address_prefixes  = ["10.1.2.0/24"]
    service_endpoints = ["Microsoft.Storage"]
  }
}
