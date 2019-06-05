output "bastion_public_ip" {
  value = "${azurerm_public_ip.bastion.ip_address}"
}

output "console_public_ip" {
  value = "${azurerm_public_ip.master.ip_address}"
}

output "api_public_domain" {
  value = "api.${data.azurerm_dns_zone.ocp.name}"
}
output "api_internal_domain" {
  value = "api-int.${data.azurerm_dns_zone.ocp.name}"
}

output "node_count" {
  value = "${var.ocp_node_count}"
}

output "master_count" {
  value = "${var.ocp_master_count}"
}

output "infra_count" {
  value = "${var.ocp_infra_count}"
}

output "admin_user" {
  value = "${var.ocp_vm_admin_user}"
}

output "ocp_admin_password" {
  value = "${random_string.ocp_admin_password.result}"
}

output "ansible_cmd" {
  value = "${local.ansible_playbook_prefix}"
}
