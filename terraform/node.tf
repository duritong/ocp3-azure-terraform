resource "azurerm_availability_set" "node" {
  name                = "ocp-node-availability-set"
  location            = "${var.location}"
  resource_group_name = "${data.azurerm_resource_group.ocp.name}"
  managed             = true
}

resource "azurerm_network_security_group" "node" {
  name                = "ocp-node-security-group"
  location            = "${var.location}"
  resource_group_name = "${data.azurerm_resource_group.ocp.name}"

  security_rule {
    name                       = "ssh"
    description                = "Allow SSH in from internal"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = "VirtualNetwork"
    destination_address_prefix = "*"
  }
  security_rule {
    name                        = "sdn"
    priority                    = 110
    direction                   = "Inbound"
    access                      = "Allow"
    protocol                    = "Udp"
    source_port_range           = "*"
    destination_port_range      = 4789
    source_address_prefix       = "VirtualNetwork"
    destination_address_prefix  = "*"
  }
  security_rule {
    name                        = "kubelet-proxy"
    priority                    = 120
    direction                   = "Inbound"
    access                      = "Allow"
    protocol                    = "Tcp"
    source_port_range           = "*"
    destination_port_range      = 10250
    source_address_prefix       = "VirtualNetwork"
    destination_address_prefix  = "*"
  }
  security_rule {
    name                        = "cri-o"
    priority                    = 130
    direction                   = "Inbound"
    access                      = "Allow"
    protocol                    = "Tcp"
    source_port_range           = "*"
    destination_port_range      = 10010
    source_address_prefix       = "VirtualNetwork"
    destination_address_prefix  = "*"
  }
  security_rule {
    name                        = "node-exporter"
    priority                    = 140
    direction                   = "Inbound"
    access                      = "Allow"
    protocol                    = "Tcp"
    source_port_range           = "*"
    destination_port_range      = 9100
    source_address_prefix       = "VirtualNetwork"
    destination_address_prefix  = "*"
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

resource "azurerm_network_interface" "node" {
  count                     = "${var.ocp_node_count}"
  name                      = "ocp-node-nic-${count.index + 1}"
  location                  = "${var.location}"
  resource_group_name       = "${data.azurerm_resource_group.ocp.name}"
  network_security_group_id = "${azurerm_network_security_group.node.id}"

  ip_configuration {
    name                          = "default"
    subnet_id                     = "${data.azurerm_subnet.node.id}"
    private_ip_address_allocation = "dynamic"
  }
}

resource "azurerm_storage_container" "node" {
  count                 = "${var.ocp_node_count}"
  name                  = "node-${count.index + 1}"
  resource_group_name   = "${data.azurerm_resource_group.ocp.name}"
  storage_account_name  = "${azurerm_storage_account.ocp.name}"
  container_access_type = "private"
}

resource "azurerm_virtual_machine" "node" {
  count                 = "${var.ocp_node_count}"
  name                  = "${var.ocp_cluster_prefix}-node-${count.index + 1}.${var.ocp_dns_zone_name}"
  location              = "${var.location}"
  resource_group_name   = "${data.azurerm_resource_group.ocp.name}"
  network_interface_ids = ["${element(azurerm_network_interface.node.*.id, count.index)}"]
  vm_size               = "${var.ocp_node_vm_size}"

  availability_set_id   = "${azurerm_availability_set.node.id}"

  storage_image_reference {
    id = "${var.ocp_os_image_ref}"
  }

  storage_os_disk {
    name              = "${var.ocp_cluster_prefix}-node-${count.index + 1}-os-disk"
    caching           = "ReadWrite"
    create_option     = "FromImage"
    managed_disk_type = "${var.ocp_disk_storage_plan}"
  }

  delete_os_disk_on_termination    = true
  delete_data_disks_on_termination = true

  os_profile {
    computer_name  = "${var.ocp_cluster_prefix}-node-${count.index + 1}.${data.azurerm_dns_zone.ocp.name}"
    admin_username = "${var.ocp_vm_admin_user}"
  }

  os_profile_linux_config {
    disable_password_authentication = true
    ssh_keys {
      path = "/home/${var.ocp_vm_admin_user}/.ssh/authorized_keys"
      key_data = "${file("${path.module}/../certs/openshift.pub")}"
    }
  }
}

resource "azurerm_managed_disk" "node_docker_disk" {
  count                = "${var.ocp_node_count}"
  name                 = "${var.ocp_cluster_prefix}-node-${count.index + 1}-docker-disk"
  location             = "${var.location}"
  resource_group_name  = "${data.azurerm_resource_group.ocp.name}"
  storage_account_type = "${var.ocp_disk_storage_plan}"
  create_option        = "Empty"
  disk_size_gb         = "${var.ocp_docker_disk_size}"
}
resource "azurerm_virtual_machine_data_disk_attachment" "node_docker_disk" {
  count              = "${var.ocp_node_count}"
  managed_disk_id    = "${element(azurerm_managed_disk.node_docker_disk.*.id, count.index)}"
  virtual_machine_id = "${element(azurerm_virtual_machine.node.*.id, count.index)}"
  lun                = 0
  caching            = "ReadWrite"
}

resource "azurerm_managed_disk" "node_emptydir_disk" {
  count                = "${var.ocp_node_count}"
  name                 = "${var.ocp_cluster_prefix}-node-${count.index + 1}-emptydir-disk"
  location             = "${var.location}"
  resource_group_name  = "${data.azurerm_resource_group.ocp.name}"
  storage_account_type = "${var.ocp_disk_storage_plan}"
  create_option        = "Empty"
  disk_size_gb         = "${var.ocp_emptydir_disk_size}"
}
resource "azurerm_virtual_machine_data_disk_attachment" "node_emptydir_disk" {
  count              = "${var.ocp_node_count}"
  managed_disk_id    = "${element(azurerm_managed_disk.node_emptydir_disk.*.id, count.index)}"
  virtual_machine_id = "${element(azurerm_virtual_machine.node.*.id, count.index)}"
  lun                = 1
  caching            = "ReadWrite"
}

resource "azurerm_dns_a_record" "ocp-node" {
  count               = "${var.ocp_node_count}"
  name                = "${var.ocp_cluster_prefix}-node-${count.index + 1}"
  zone_name           = "${data.azurerm_dns_zone.ocp.name}"
  resource_group_name = "${data.azurerm_dns_zone.ocp.resource_group_name}"
  ttl                 = 300
  records             = ["${element(azurerm_network_interface.node.*.private_ip_address, count.index)}"]
}
