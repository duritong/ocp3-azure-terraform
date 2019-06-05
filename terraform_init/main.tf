# Specify the provider and access details
provider "azurerm" {}
data "azurerm_subscription" "main" {}
data "azurerm_client_config" "current" {}

# Create a resource group
resource "azurerm_resource_group" "ocp" {
  name     = "${var.resource_group_name}"
  location = "${var.location}"
}

# Create a virtual network within the resource group
resource "azurerm_virtual_network" "ocpvnet" {
  name                = "${var.ocpvnet_name}"
  resource_group_name = "${azurerm_resource_group.ocp.name}"
  location            = "${azurerm_resource_group.ocp.location}"
  address_space       = "${var.ocpvnet_addr_space}"

}

# OpenShift DEV Mgmt
resource "azurerm_subnet" "ocpvnet_master_subnet" {
  name                 = "${var.ocpvnet_master_subnet_name}"
  resource_group_name  = "${azurerm_resource_group.ocp.name}"
  virtual_network_name = "${azurerm_virtual_network.ocpvnet.name}"
  address_prefix       = "${var.ocpvnet_master_subnet}"
}

# OpenShift DEV App
resource "azurerm_subnet" "ocpvnet_node_subnet" {
  name                 = "${var.ocpvnet_node_subnet_name}"
  resource_group_name  = "${azurerm_resource_group.ocp.name}"
  virtual_network_name = "${azurerm_virtual_network.ocpvnet.name}"
  address_prefix       = "${var.ocpvnet_node_subnet}"
}
