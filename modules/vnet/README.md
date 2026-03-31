# Azure VNET Terraform Module

Reusable Terraform module for provisioning an Azure Virtual Network with subnets and Network Security Groups.

## Features

- Configurable VNET with custom address space and DNS servers
- Dynamic subnet creation with service endpoints and private endpoint policies
- Optional Network Security Groups (NSGs) per subnet with custom rules
- Automatic NSG-to-subnet association
- Consistent tagging across all resources

## Usage

```hcl
module "vnet" {
  source = "../../modules/vnet"

  vnet_name           = "vnet-myapp-dev-eastus"
  resource_group_name = azurerm_resource_group.this.name
  location            = "eastus"
  address_space       = ["10.0.0.0/16"]

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

  nsg_rules = {
    "snet-app" = [
      {
        name                   = "allow-https-inbound"
        priority               = 100
        direction              = "Inbound"
        access                 = "Allow"
        protocol               = "Tcp"
        destination_port_range = "443"
      }
    ]
  }

  tags = {
    Environment = "dev"
    ManagedBy   = "terraform"
  }
}
```

## Requirements

| Name      | Version  |
|-----------|----------|
| terraform | >= 1.5.0 |
| azurerm   | ~> 4.0   |

## Inputs

| Name                     | Description                                              | Type                | Default        | Required |
|--------------------------|----------------------------------------------------------|---------------------|----------------|----------|
| vnet_name                | Name of the Virtual Network                              | `string`            | n/a            | yes      |
| resource_group_name      | Name of the resource group                               | `string`            | n/a            | yes      |
| location                 | Azure region for the VNET                                | `string`            | n/a            | yes      |
| address_space            | Address space in CIDR notation                           | `list(string)`      | `["10.0.0.0/16"]` | no   |
| dns_servers              | Custom DNS servers (empty = Azure default)               | `list(string)`      | `[]`           | no       |
| subnets                  | Map of subnet configurations                             | `map(object({...}))` | `{}`          | no       |
| nsg_rules                | Map of NSG rules per subnet                              | `map(list(object))` | `{}`           | no       |
| enable_ddos_protection   | Enable DDoS Protection Plan                              | `bool`              | `false`        | no       |
| tags                     | Tags to apply to all resources                           | `map(string)`       | `{}`           | no       |

## Outputs

| Name                   | Description                               |
|------------------------|-------------------------------------------|
| vnet_id                | The ID of the Virtual Network             |
| vnet_name              | The name of the Virtual Network           |
| vnet_address_space     | The address space of the VNET             |
| subnet_ids             | Map of subnet names to their IDs          |
| subnet_address_prefixes| Map of subnet names to address prefixes   |
| nsg_ids                | Map of NSG names to their IDs             |

## Automated Documentation

This module's documentation can be auto-generated using [terraform-docs](https://terraform-docs.io/):

```bash
terraform-docs markdown table modules/vnet > modules/vnet/README.md
```

To enforce this in CI, add a pre-commit hook or pipeline step:

```bash
terraform-docs markdown table --output-file README.md --output-mode inject modules/vnet
```
