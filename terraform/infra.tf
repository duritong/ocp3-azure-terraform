resource "azurerm_public_ip" "infra" {
  name                = "ocp-infra-public-ip"
  location            = "${var.location}"
  resource_group_name = "${data.azurerm_resource_group.ocp.name}"
  allocation_method   = "Static"
}

resource "azurerm_dns_a_record" "apps" {
  name                = "*.apps${var.ocp_dns_base}"
  zone_name           = "${data.azurerm_dns_zone.ocp.name}"
  resource_group_name = "${data.azurerm_dns_zone.ocp.resource_group_name}"
  ttl                 = 300
  records             = ["${azurerm_public_ip.infra.ip_address}"]
}

resource "azurerm_availability_set" "infra" {
  name                = "ocp-infra-availability-set"
  location            = "${var.location}"
  resource_group_name = "${data.azurerm_resource_group.ocp.name}"
  managed             = true
}

resource "azurerm_lb" "infra" {
  name                = "ocp-infra-load-balancer"
  location            = "${var.location}"
  resource_group_name = "${data.azurerm_resource_group.ocp.name}"

  frontend_ip_configuration {
    name                          = "default"
    public_ip_address_id          = "${azurerm_public_ip.infra.id}"
    private_ip_address_allocation = "dynamic"
  }
}

resource "azurerm_lb_backend_address_pool" "infra" {
  name                = "ocp-infra-address-pool"
  resource_group_name = "${data.azurerm_resource_group.ocp.name}"
  loadbalancer_id     = "${azurerm_lb.infra.id}"
}

resource "azurerm_network_interface_backend_address_pool_association" "infra" {
  count                   = "${var.ocp_infra_count}"
  network_interface_id    = "${element(azurerm_network_interface.infra.*.id, count.index)}"
  ip_configuration_name   = "default"
  backend_address_pool_id = "${azurerm_lb_backend_address_pool.infra.id}"
}

resource "azurerm_lb_rule" "infra-80-80" {
  name                    = "infra-lb-rule-80-80"
  resource_group_name     = "${data.azurerm_resource_group.ocp.name}"
  loadbalancer_id         = "${azurerm_lb.infra.id}"
  backend_address_pool_id = "${azurerm_lb_backend_address_pool.infra.id}"
  protocol                       = "tcp"
  frontend_port                  = 80
  backend_port                   = 80
  frontend_ip_configuration_name = "default"
}

resource "azurerm_lb_rule" "infra-443-443" {
  name                    = "infra-lb-rule-443-443"
  resource_group_name     = "${data.azurerm_resource_group.ocp.name}"
  loadbalancer_id         = "${azurerm_lb.infra.id}"
  backend_address_pool_id = "${azurerm_lb_backend_address_pool.infra.id}"
  protocol                       = "tcp"
  frontend_port                  = 443
  backend_port                   = 443
  frontend_ip_configuration_name = "default"
}

resource "azurerm_network_security_group" "infra" {
  name                = "ocp-infra-security-group"
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
    name                        = "http"
    priority                    = 110
    direction                   = "Inbound"
    access                      = "Allow"
    protocol                    = "Tcp"
    source_port_range           = "*"
    destination_port_range      = 80
    source_address_prefix       = "VirtualNetwork"
    destination_address_prefix  = "*"
  }
  security_rule {
    name                        = "https"
    priority                    = 120
    direction                   = "Inbound"
    access                      = "Allow"
    protocol                    = "Tcp"
    source_port_range           = "*"
    destination_port_range      = 443
    source_address_prefix       = "VirtualNetwork"
    destination_address_prefix  = "*"
  }
  security_rule {
    name                        = "http-lb"
    priority                    = 115
    direction                   = "Inbound"
    access                      = "Allow"
    protocol                    = "Tcp"
    source_port_range           = "*"
    destination_port_range      = 80
    source_address_prefix       = "*"
    destination_address_prefix  = "*"
  }
  security_rule {
    name                        = "https-lb"
    priority                    = 125
    direction                   = "Inbound"
    access                      = "Allow"
    protocol                    = "Tcp"
    source_port_range           = "*"
    destination_port_range      = 443
    source_address_prefix       = "*"
    destination_address_prefix  = "*"
  }
  security_rule {
    name                        = "sdn"
    priority                    = 130
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
    priority                    = 140
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
    priority                    = 150
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
    priority                    = 160
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

resource "azurerm_network_interface" "infra" {
  count                     = "${var.ocp_infra_count}"
  name                      = "ocp-infra-nic-${count.index + 1}"
  location                  = "${var.location}"
  resource_group_name       = "${data.azurerm_resource_group.ocp.name}"
  network_security_group_id = "${azurerm_network_security_group.infra.id}"

  ip_configuration {
    name                                    = "default"
    subnet_id                               = "${data.azurerm_subnet.master.id}"
    private_ip_address_allocation           = "dynamic"
  }
}

resource "azurerm_virtual_machine" "infra" {
  count                 = "${var.ocp_infra_count}"
  name                  = "${var.ocp_cluster_prefix}-infra-${count.index + 1}.${var.ocp_dns_zone_name}"
  location              = "${var.location}"
  resource_group_name   = "${data.azurerm_resource_group.ocp.name}"
  network_interface_ids = ["${element(azurerm_network_interface.infra.*.id, count.index)}"]
  vm_size               = "${var.ocp_infra_vm_size}"
  availability_set_id   = "${azurerm_availability_set.infra.id}"

  storage_image_reference {
    id = "${var.ocp_os_image_ref}"
  }

  storage_os_disk {
    name              = "${var.ocp_cluster_prefix}-infra-${count.index + 1}-os-disk"
    caching           = "ReadWrite"
    create_option     = "FromImage"
    managed_disk_type = "Standard_LRS"
  }

  delete_os_disk_on_termination    = true
  delete_data_disks_on_termination = true

  os_profile {
    computer_name  = "${var.ocp_cluster_prefix}-infra-${count.index + 1}.${var.ocp_dns_zone_name}"
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
resource "azurerm_managed_disk" "infra_docker_disk" {
  count                = "${var.ocp_infra_count}"
  name                 = "${var.ocp_cluster_prefix}-infra-${count.index + 1}-docker-disk"
  location             = "${var.location}"
  resource_group_name  = "${data.azurerm_resource_group.ocp.name}"
  storage_account_type = "Standard_LRS"
  create_option        = "Empty"
  disk_size_gb         = "${var.ocp_docker_disk_size}"
}
resource "azurerm_virtual_machine_data_disk_attachment" "infra_docker_disk" {
  count              = "${var.ocp_infra_count}"
  managed_disk_id    = "${element(azurerm_managed_disk.infra_docker_disk.*.id, count.index)}"
  virtual_machine_id = "${element(azurerm_virtual_machine.infra.*.id, count.index)}"
  lun                = 0
  caching            = "ReadWrite"
}

resource "azurerm_managed_disk" "infra_emptydir_disk" {
  count                = "${var.ocp_infra_count}"
  name                 = "${var.ocp_cluster_prefix}-infra-${count.index + 1}-emptydir-disk"
  location             = "${var.location}"
  resource_group_name  = "${data.azurerm_resource_group.ocp.name}"
  storage_account_type = "Standard_LRS"
  create_option        = "Empty"
  disk_size_gb         = "${var.ocp_emptydir_disk_size}"
}
resource "azurerm_virtual_machine_data_disk_attachment" "infra_emptydir_disk" {
  count              = "${var.ocp_infra_count}"
  managed_disk_id    = "${element(azurerm_managed_disk.infra_emptydir_disk.*.id, count.index)}"
  virtual_machine_id = "${element(azurerm_virtual_machine.infra.*.id, count.index)}"
  lun                = 1
  caching            = "ReadWrite"
}

resource "azurerm_dns_a_record" "ocp-infra" {
  count               = "${var.ocp_infra_count}"
  name                = "${var.ocp_cluster_prefix}-infra-${count.index + 1}"
  zone_name           = "${data.azurerm_dns_zone.ocp.name}"
  resource_group_name = "${data.azurerm_dns_zone.ocp.resource_group_name}"
  ttl                 = 300
  records             = ["${element(azurerm_network_interface.infra.*.private_ip_address, count.index)}"]
}
