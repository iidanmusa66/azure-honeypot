# 1. SETUP
terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.0"
    }
  }
}

provider "azurerm" {
  features {}
}

# 2. RESOURCE GROUP
resource "azurerm_resource_group" "rg_honeypot" {
  name     = "rg-honeypot-lab"
  location = "West Europe"
}

# 3. NETWORK (The Streets)
resource "azurerm_virtual_network" "vnet" {
  name                = "vnet-honeypot"
  location            = azurerm_resource_group.rg_honeypot.location
  resource_group_name = azurerm_resource_group.rg_honeypot.name
  address_space       = ["10.0.0.0/16"]
}

resource "azurerm_subnet" "subnet" {
  name                 = "subnet-dmz"
  resource_group_name  = azurerm_resource_group.rg_honeypot.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = ["10.0.1.0/24"]
}

# 4. PUBLIC IP (So you can attack it from home)
resource "azurerm_public_ip" "public_ip" {
  name                = "pip-honeypot"
  location            = azurerm_resource_group.rg_honeypot.location
  resource_group_name = azurerm_resource_group.rg_honeypot.name
  allocation_method   = "Dynamic"
}

# 5. FIREWALL (Opening the Door)
resource "azurerm_network_security_group" "nsg" {
  name                = "nsg-honeypot"
  location            = azurerm_resource_group.rg_honeypot.location
  resource_group_name = azurerm_resource_group.rg_honeypot.name

  # DANGEROUS: Allowing SSH from ANYWHERE
  security_rule {
    name                       = "Allow-SSH-All"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = "*" 
    destination_address_prefix = "*"
  }
}

# 6. NETWORK INTERFACE (The Network Card)
resource "azurerm_network_interface" "nic" {
  name                = "nic-honeypot"
  location            = azurerm_resource_group.rg_honeypot.location
  resource_group_name = azurerm_resource_group.rg_honeypot.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.subnet.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.public_ip.id
  }
}

# Connect Firewall to NIC
resource "azurerm_network_interface_security_group_association" "connect_nsg" {
  network_interface_id      = azurerm_network_interface.nic.id
  network_security_group_id = azurerm_network_security_group.nsg.id
}

# 7. THE VIRTUAL MACHINE (The Target)
resource "azurerm_linux_virtual_machine" "vm_honeypot" {
  name                = "vm-target-01"
  resource_group_name = azurerm_resource_group.rg_honeypot.name
  location            = azurerm_resource_group.rg_honeypot.location
  size                = "Standard_B1s" # Cheapest option
  admin_username      = "adminuser"
  network_interface_ids = [
    azurerm_network_interface.nic.id,
  ]

  # SSH Key Auth (More secure than password)
  # This tells Terraform to create a key pair for you locally if you use a "tls_private_key" resource, 
  # but for simplicity, we will use a password here to make it easy for you to log in.
  
  # SWITCHING TO PASSWORD AUTH FOR EASE OF USE IN LAB
  disable_password_authentication = false
  admin_password                  = "P@ssw0rd1234!" # Change this if you want!

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "18.04-LTS"
    version   = "latest"
  }

  # 8. BOOTSTRAP SCRIPT (The Magic)
  # This runs the moment the server turns on. It installs Apache.
  custom_data = base64encode(<<-EOF
              #!/bin/bash
              apt-get update
              apt-get install -y apache2
              systemctl start apache2
              systemctl enable apache2
              echo "<h1>YOU HAVE BEEN HACKED</h1>" > /var/www/html/index.html
              EOF
  )
}

# 9. OUTPUT (Tell me the IP address when done)
output "public_ip_address" {
  value = azurerm_public_ip.public_ip.ip_address
}