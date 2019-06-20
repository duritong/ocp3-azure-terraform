resource "random_id" "storage" {
  byte_length = 8
  prefix      = "${azurerm_resource_group.ocp.name}-"
}
resource "azurerm_storage_account" "ocp" {
  name                      = "ocp${substr(lower(replace("${random_id.storage.hex}", "-", "")), 0, 10)}"
  resource_group_name       = "${azurerm_resource_group.ocp.name}"
  location                  = "${var.location}"
  account_tier              = "Standard"
  account_replication_type  = "LRS"
}

resource "azurerm_storage_account" "registry" {
  name                      = "registry${substr(lower(replace("${random_id.storage.hex}", "-", "")), 0, 10)}"
  resource_group_name       = "${azurerm_resource_group.ocp.name}"
  location                  = "${azurerm_resource_group.ocp.location}"
  account_tier              = "Standard"
  account_replication_type  = "LRS"
}
