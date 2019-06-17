provider "azurerm" {}
data "azurerm_subscription" "main" {}
data "azurerm_client_config" "current" {}

data "azurerm_resource_group" "ocp" {
  name     = "${var.resource_group_name}"
}

resource "random_id" "azure_app" {
  byte_length = 8
  prefix      = "ocp-${data.azurerm_resource_group.ocp.name}-"
}

resource "azuread_application" "azure_app" {
  name                       = "${random_id.azure_app.hex}"
  available_to_other_tenants = false
}

resource "azuread_service_principal" "azure_app" {
  application_id = "${azuread_application.azure_app.application_id}"
}

resource "random_string" "ad_password" {
  length  = 32
  special = true
}

resource "azuread_service_principal_password" "azure_app" {
  service_principal_id = "${azuread_service_principal.azure_app.id}"
  value                = "${random_string.ad_password.result}"
  end_date_relative    = "17520h"
}

resource "azurerm_role_assignment" "azure_app" {
  scope                = "${data.azurerm_subscription.main.id}/resourceGroups/${data.azurerm_resource_group.ocp.name}"
  role_definition_name = "Contributor"
  principal_id         = "${azuread_service_principal.azure_app.id}"
}

resource "random_id" "acme_app" {
  byte_length = 8
  prefix      = "acme-${data.azurerm_resource_group.ocp.name}-"
}

resource "azuread_application" "acme_app" {
  name                       = "${random_id.acme_app.hex}"
  available_to_other_tenants = false
}

resource "azuread_service_principal" "acme_app" {
  application_id = "${azuread_application.acme_app.application_id}"
}

resource "random_string" "acme_password" {
  length  = 32
  special = true
}

resource "azuread_service_principal_password" "acme_app" {
  service_principal_id = "${azuread_service_principal.acme_app.id}"
  value                = "${random_string.acme_password.result}"
  end_date_relative    = "17520h"
}

resource "azurerm_role_assignment" "acme_app" {
  scope                = "${data.azurerm_dns_zone.ocp.id}"
  role_definition_name = "DNS Zone Contributor"
  principal_id         = "${azuread_service_principal.acme_app.id}"
}
