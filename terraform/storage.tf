resource "azurerm_storage_account" "ocp" {
  name                      = "ocp${lower(replace(substr(uuid(), 0, 10), "-", ""))}"
  resource_group_name       = "${data.azurerm_resource_group.ocp.name}"
  location                  = "${var.location}"
  account_tier              = "Standard"
  account_replication_type  = "LRS"
  lifecycle {
      ignore_changes        = ["name"]
  }
}

resource "azurerm_storage_account" "registry" {
  name                      = "registry${lower(replace(substr(uuid(), 0, 10), "-", ""))}"
  resource_group_name       = "${data.azurerm_resource_group.ocp.name}"
  location                  = "${data.azurerm_resource_group.ocp.location}"
  account_tier              = "Standard"
  account_replication_type  = "LRS"
  lifecycle {
      ignore_changes        = ["name"]
  }

}
