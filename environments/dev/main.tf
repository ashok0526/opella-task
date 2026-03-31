resource "azurerm_resource_group" "this" {
  name     = "rg-${local.name_prefix}"
  location = var.location

  tags = local.common_tags
}

module "vnet" {
  source = "../../modules/vnet"

  vnet_name           = "vnet-${local.name_prefix}"
  resource_group_name = azurerm_resource_group.this.name
  location            = var.location
  address_space       = var.vnet_address_space
  subnets             = var.subnets

  nsg_rules = {
    "snet-app" = [
      {
        name                   = "allow-http-inbound"
        priority               = 100
        direction              = "Inbound"
        access                 = "Allow"
        protocol               = "Tcp"
        destination_port_range = "80"
      },
      {
        name                   = "allow-https-inbound"
        priority               = 110
        direction              = "Inbound"
        access                 = "Allow"
        protocol               = "Tcp"
        destination_port_range = "443"
      },
      {
        name                   = "allow-ssh-inbound"
        priority               = 120
        direction              = "Inbound"
        access                 = "Allow"
        protocol               = "Tcp"
        destination_port_range = "22"
      },
      {
        name      = "deny-all-inbound"
        priority  = 4096
        direction = "Inbound"
        access    = "Deny"
        protocol  = "*"
      }
    ]
  }

  tags = local.common_tags
}

resource "azurerm_storage_account" "this" {
  name                     = replace("st${var.project}${var.environment}${var.location}", "-", "")
  resource_group_name      = azurerm_resource_group.this.name
  location                 = var.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
  min_tls_version          = "TLS1_2"

  blob_properties {
    versioning_enabled = true

    delete_retention_policy {
      days = 7
    }
  }

  network_rules {
    default_action             = "Deny"
    virtual_network_subnet_ids = [module.vnet.subnet_ids["snet-data"]]
    bypass                     = ["AzureServices"]
  }

  tags = local.common_tags
}

resource "azurerm_storage_container" "data" {
  name                  = "data"
  storage_account_id    = azurerm_storage_account.this.id
  container_access_type = "private"
}
