# Azure Firewall Configuration
# Automated firewall rule provisioning - BRIT Insurance
# Author: Nimisha Chelladurai

resource "azurerm_public_ip" "firewall_pip" {
  name                = "${var.prefix}-firewall-pip"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  allocation_method   = "Static"
  sku                 = "Standard"

  tags = {
    Environment = var.environment
    ManagedBy   = "Terraform"
  }
}

resource "azurerm_subnet" "firewall_subnet" {
  name                 = "AzureFirewallSubnet"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = ["10.0.2.0/24"]
}

resource "azurerm_firewall" "firewall" {
  name                = "${var.prefix}-firewall"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  sku_name            = "AZFW_VNet"
  sku_tier            = "Standard"

  ip_configuration {
    name                 = "configuration"
    subnet_id            = azurerm_subnet.firewall_subnet.id
    public_ip_address_id = azurerm_public_ip.firewall_pip.id
  }

  tags = {
    Environment = var.environment
    ManagedBy   = "Terraform"
  }
}

# Network Rules
resource "azurerm_firewall_network_rule_collection" "network_rules" {
  name                = "AllowedNetworkRules"
  azure_firewall_name = azurerm_firewall.firewall.name
  resource_group_name = azurerm_resource_group.rg.name
  priority            = 100
  action              = "Allow"

  rule {
    name                  = "Allow-DNS"
    protocols             = ["UDP"]
    source_addresses      = ["10.0.0.0/16"]
    destination_addresses = ["8.8.8.8", "8.8.4.4"]
    destination_ports     = ["53"]
  }

  rule {
    name                  = "Allow-NTP"
    protocols             = ["UDP"]
    source_addresses      = ["10.0.0.0/16"]
    destination_addresses = ["*"]
    destination_ports     = ["123"]
  }
}

# Application Rules
resource "azurerm_firewall_application_rule_collection" "app_rules" {
  name                = "AllowedAppRules"
  azure_firewall_name = azurerm_firewall.firewall.name
  resource_group_name = azurerm_resource_group.rg.name
  priority            = 200
  action              = "Allow"

  rule {
    name             = "Allow-Microsoft"
    source_addresses = ["10.0.0.0/16"]

    target_fqdns = [
      "*.microsoft.com",
      "*.windows.net",
      "*.azure.com",
      "*.windowsupdate.com"
    ]

    protocol {
      port = "443"
      type = "Https"
    }
  }
}

# NAT Rules - Inbound traffic
resource "azurerm_firewall_nat_rule_collection" "nat_rules" {
  name                = "InboundNATRules"
  azure_firewall_name = azurerm_firewall.firewall.name
  resource_group_name = azurerm_resource_group.rg.name
  priority            = 300
  action              = "Dnat"

  rule {
    name                  = "RDP-NAT"
    protocols             = ["TCP"]
    source_addresses      = [var.allowed_ip]
    destination_addresses = [azurerm_public_ip.firewall_pip.ip_address]
    destination_ports     = ["3389"]
    translated_address    = "10.0.1.4"
    translated_port       = "3389"
  }
}
