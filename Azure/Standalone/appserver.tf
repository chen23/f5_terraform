# Backend VM - web server running DVWA

# Create random password for app server
resource random_string password {
  length           = 16
  min_upper        = 1
  min_lower        = 1
  min_numeric      = 1
  special          = false
  override_special = " #%*+,-./:=?@[]^_~"
}

# Create NIC
resource "azurerm_network_interface" "backend01-ext-nic" {
  name                = "${var.prefix}-backend01-ext-nic"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  ip_configuration {
    name                          = "primary"
    subnet_id                     = data.azurerm_subnet.external-public.id
    private_ip_address_allocation = "Dynamic"
  }

  tags = {
    environment = var.environment
    costcenter  = var.costcenter
    application = "app1"
  }
}

# Associate network security groups with NICs
resource "azurerm_network_interface_security_group_association" "backend01-ext-nsg" {
  network_interface_id      = azurerm_network_interface.backend01-ext-nic.id
  network_security_group_id = module.external-network-security-group-public.network_security_group_id
}

# Setup Onboarding scripts
locals {
  backendvm_custom_data = <<EOF
#!/bin/bash
apt-get update -y
apt-get install -y docker.io
docker run -d -p 80:80 --net=host --restart unless-stopped vulnerables/web-dvwa
EOF
}

# Create backend VM
resource "azurerm_linux_virtual_machine" "backendvm" {
  name                            = "backendvm"
  location                        = azurerm_resource_group.rg.location
  resource_group_name             = azurerm_resource_group.rg.name
  network_interface_ids           = [azurerm_network_interface.backend01-ext-nic.id]
  size                            = "Standard_B1ms"
  admin_username                  = var.f5_username
  admin_password                  = random_string.password.result
  disable_password_authentication = false
  computer_name                   = "backend01"
  custom_data                     = base64encode(local.backendvm_custom_data)

  os_disk {
    name                 = "backendOsDisk"
    caching              = "ReadWrite"
    storage_account_type = "Premium_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "18.04-LTS"
    version   = "latest"
  }

  tags = {
    environment = var.environment
    costcenter  = var.costcenter
  }
}
