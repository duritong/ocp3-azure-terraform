data "azurerm_virtual_network" "ocpvnet" {
  name                = "${var.ocpvnet_name}"
  resource_group_name = "${data.azurerm_resource_group.ocp.name}"
}

data "azurerm_subnet" "master" {
  name                 = "${var.ocpvnet_master_subnet_name}"
  resource_group_name  = "${data.azurerm_resource_group.ocp.name}"
  virtual_network_name = "${data.azurerm_virtual_network.ocpvnet.name}"
}

data "azurerm_subnet" "node" {
  name                 = "${var.ocpvnet_node_subnet_name}"
  resource_group_name  = "${data.azurerm_resource_group.ocp.name}"
  virtual_network_name = "${data.azurerm_virtual_network.ocpvnet.name}"
}

data "azurerm_dns_zone" "ocp" {
  name = "${var.ocp_dns_zone_name}"
}
