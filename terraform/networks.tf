# Create a virtual network within the resource group
resource "azurerm_virtual_network" "ocpvnet" {
  name                = "${var.ocpvnet_name}"
  resource_group_name = "${azurerm_resource_group.ocp.name}"
  location            = "${azurerm_resource_group.ocp.location}"
  address_space       = "${var.ocpvnet_addr_space}"

}

# OpenShift DEV Mgmt
resource "azurerm_subnet" "master" {
  name                 = "${var.ocpvnet_master_subnet_name}"
  resource_group_name  = "${azurerm_resource_group.ocp.name}"
  virtual_network_name = "${azurerm_virtual_network.ocpvnet.name}"
  address_prefix       = "${var.ocpvnet_master_subnet}"
}

# OpenShift DEV App
resource "azurerm_subnet" "node" {
  name                 = "${var.ocpvnet_node_subnet_name}"
  resource_group_name  = "${azurerm_resource_group.ocp.name}"
  virtual_network_name = "${azurerm_virtual_network.ocpvnet.name}"
  address_prefix       = "${var.ocpvnet_node_subnet}"
}

data "azurerm_dns_zone" "ocp" {
  name = "${var.ocp_dns_zone_name}"
}
