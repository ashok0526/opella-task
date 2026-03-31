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

resource "azurerm_public_ip" "vm" {
  name                = "pip-vm-${local.name_prefix}"
  location            = var.location
  resource_group_name = azurerm_resource_group.this.name
  allocation_method   = "Static"
  sku                 = "Standard"

  tags = local.common_tags
}

resource "azurerm_network_interface" "vm" {
  name                = "nic-vm-${local.name_prefix}"
  location            = var.location
  resource_group_name = azurerm_resource_group.this.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = module.vnet.subnet_ids["snet-app"]
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.vm.id
  }

  tags = local.common_tags
}

resource "azurerm_linux_virtual_machine" "this" {
  name                            = "vm-${local.name_prefix}"
  location                        = var.location
  resource_group_name             = azurerm_resource_group.this.name
  size                            = var.vm_size
  admin_username                  = var.vm_admin_username
  disable_password_authentication = true
  network_interface_ids           = [azurerm_network_interface.vm.id]

  admin_ssh_key {
    username   = var.vm_admin_username
    public_key = var.vm_ssh_public_key
  }

  os_disk {
    name                 = "osdisk-vm-${local.name_prefix}"
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-jammy"
    sku       = "22_04-lts-gen2"
    version   = "latest"
  }

  tags = local.common_tags
}
