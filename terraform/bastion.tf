resource "azurerm_public_ip" "bastion" {
  name                = "${var.ocp_cluster_prefix}-bastion-public-ip"
  location            = "${var.location}"
  resource_group_name = "${azurerm_resource_group.ocp.name}"
  allocation_method   = "Static"
}

resource "azurerm_dns_a_record" "bastion" {
  name                = "bastion${var.ocp_dns_base}"
  zone_name           = "${data.azurerm_dns_zone.ocp.name}"
  resource_group_name = "${data.azurerm_dns_zone.ocp.resource_group_name}"
  ttl                 = 300
  records             = ["${azurerm_public_ip.bastion.ip_address}"]
}

resource "azurerm_network_interface" "bastion" {
  name                      = "${var.ocp_cluster_prefix}-bastion-nic"
  location                  = "${var.location}"
  resource_group_name       = "${azurerm_resource_group.ocp.name}"
  network_security_group_id = "${azurerm_network_security_group.bastion.id}"

  ip_configuration {
    name                          = "default"
    public_ip_address_id          = "${azurerm_public_ip.bastion.id}"
    subnet_id                     = "${azurerm_subnet.master.id}"
    private_ip_address_allocation = "dynamic"
  }
}

resource "azurerm_network_security_group" "bastion" {
  name                = "${var.ocp_cluster_prefix}-bastion-security-group"
  location            = "${var.location}"
  resource_group_name = "${azurerm_resource_group.ocp.name}"

  security_rule {
    name                       = "ssh"
    description                = "Allow SSH in from all locations"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = "Internet"
    destination_address_prefix = "*"
  }
  security_rule {
    name                       = "deny-by-default"
    description                = "Deny anything else"
    priority                   = 900
    direction                  = "Inbound"
    access                     = "Deny"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
}

resource "azurerm_virtual_machine" "bastion" {
  name                  = "${var.ocp_cluster_prefix}-bastion${var.ocp_node_dns_suffix}.${var.ocp_dns_zone_name}"
  location              = "${var.location}"
  resource_group_name   = "${azurerm_resource_group.ocp.name}"
  network_interface_ids = ["${azurerm_network_interface.bastion.id}"]
  vm_size               = "${var.ocp_bastion_vm_size}"

  depends_on = [azurerm_role_assignment.acme_app]

  storage_image_reference {
    id = "${var.ocp_os_image_ref}"
  }

  storage_os_disk {
    name              = "${var.ocp_cluster_prefix}-bastion-os-disk"
    caching           = "ReadWrite"
    create_option     = "FromImage"
    managed_disk_type = "${var.ocp_disk_storage_plan}"
  }

  delete_os_disk_on_termination    = true
  delete_data_disks_on_termination = true

  os_profile {
    computer_name  = "${var.ocp_cluster_prefix}-bastion${var.ocp_node_dns_suffix}.${var.ocp_dns_zone_name}"
    admin_username = "${var.ocp_vm_admin_user}"
  }

  os_profile_linux_config {
    disable_password_authentication = true
    ssh_keys {
      path = "/home/${var.ocp_vm_admin_user}/.ssh/authorized_keys"
      key_data = "${tls_private_key.bastion.public_key_openssh}"
    }
  }

  provisioner "file" {
    source = "${path.module}/provision/bastion.sh"
    destination = "/home/${var.ocp_vm_admin_user}/bastion.sh"

    connection {
      type        = "ssh"
      host        = "${azurerm_public_ip.bastion.ip_address}"
      user        = "${var.ocp_vm_admin_user}"
      private_key = "${tls_private_key.bastion.private_key_pem}"
    }
  }
  provisioner "file" {
    source = "${path.module}/ansible"
    destination = "/home/${var.ocp_vm_admin_user}/ocp"

    connection {
      type        = "ssh"
      host        = "${azurerm_public_ip.bastion.ip_address}"
      user        = "${var.ocp_vm_admin_user}"
      private_key = "${tls_private_key.bastion.private_key_pem}"
    }
  }
  provisioner "file" {
    source = "${tls_private_key.openshift.private_key_pem}"
    destination = "/home/${var.ocp_vm_admin_user}/.ssh/id_rsa"

    connection {
      type        = "ssh"
      host        = "${azurerm_public_ip.bastion.ip_address}"
      user        = "${var.ocp_vm_admin_user}"
      private_key = "${tls_private_key.bastion.private_key_pem}"
    }
  }
  provisioner "remote-exec" {
    inline = [
      "chmod +x /home/${var.ocp_vm_admin_user}/bastion.sh",
      "chmod og-rwx /home/${var.ocp_vm_admin_user}/.ssh/id_rsa",
      "/home/${var.ocp_vm_admin_user}/bastion.sh ${var.rh_activation_key} ${var.rh_org} ${var.rh_infra_pool_id} ${data.azurerm_client_config.current.subscription_id} ${data.azurerm_client_config.current.tenant_id} ${azuread_application.acme_app.application_id} '${azuread_service_principal_password.acme_app.value}' '${var.ocp_dns_base}.${var.ocp_dns_zone_name}'",
      "sudo shutdown -r +0",
    ]

    connection {
      type        = "ssh"
      host        = "${azurerm_public_ip.bastion.ip_address}"
      user        = "${var.ocp_vm_admin_user}"
      private_key = "${tls_private_key.bastion.private_key_pem}"
    }
  }
  provisioner "local-exec" {
    command = "sleep 10 && ${path.module}/wait_port.sh ${azurerm_public_ip.bastion.ip_address} 22"
    working_dir = "${path.module}"
  }
}

resource "azurerm_dns_a_record" "ocp-bastion" {
  name                = "${var.ocp_cluster_prefix}-bastion${var.ocp_node_dns_suffix}"
  zone_name           = "${data.azurerm_dns_zone.ocp.name}"
  resource_group_name = "${data.azurerm_dns_zone.ocp.resource_group_name}"
  ttl                 = 300
  records             = ["${azurerm_network_interface.bastion.private_ip_address}"]
}
