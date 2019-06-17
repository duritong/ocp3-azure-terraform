resource "random_string" "master" {
  length = 16
  special = false
  upper = false
}

resource "azurerm_public_ip" "master" {
  name                = "ocp-master-public-ip"
  location            = "${var.location}"
  resource_group_name = "${data.azurerm_resource_group.ocp.name}"
  allocation_method   = "Static"
  domain_name_label   = "ocp-${random_string.master.result}"
  sku                 = "Standard"
}

resource "azurerm_dns_a_record" "api" {
  name                = "api"
  zone_name           = "${data.azurerm_dns_zone.ocp.name}"
  resource_group_name = "${data.azurerm_dns_zone.ocp.resource_group_name}"
  ttl                 = 300
  records             = ["${azurerm_public_ip.master.ip_address}"]
}
resource "azurerm_dns_a_record" "api-int" {
  name                = "api-int"
  zone_name           = "${data.azurerm_dns_zone.ocp.name}"
  resource_group_name = "${data.azurerm_dns_zone.ocp.resource_group_name}"
  ttl                 = 300
  records             = ["${azurerm_public_ip.master.ip_address}"]
}

resource "azurerm_availability_set" "master" {
  name                = "ocp-master-availability-set"
  location            = "${var.location}"
  resource_group_name = "${data.azurerm_resource_group.ocp.name}"
  managed             = true
}

resource "azurerm_lb" "master" {
  name                = "ocp-master-load-balancer"
  location            = "${var.location}"
  resource_group_name = "${data.azurerm_resource_group.ocp.name}"
  sku                 = "Standard"

  frontend_ip_configuration {
    name                          = "default"
    public_ip_address_id          = "${azurerm_public_ip.master.id}"
    private_ip_address_allocation = "Dynamic"
  }
}

resource "azurerm_lb_backend_address_pool" "master" {
  name                = "ocp-master-address-pool"
  resource_group_name = "${data.azurerm_resource_group.ocp.name}"
  loadbalancer_id     = "${azurerm_lb.master.id}"
}

resource "azurerm_network_interface_backend_address_pool_association" "master" {
  count                   = "${var.ocp_master_count}"
  network_interface_id    = "${element(azurerm_network_interface.master.*.id, count.index)}"
  ip_configuration_name   = "default"
  backend_address_pool_id = "${azurerm_lb_backend_address_pool.master.id}"
}

resource "azurerm_lb_rule" "master-443-443" {
  name                    = "master-lb-rule-443-443"
  resource_group_name     = "${data.azurerm_resource_group.ocp.name}"
  loadbalancer_id         = "${azurerm_lb.master.id}"
  backend_address_pool_id = "${azurerm_lb_backend_address_pool.master.id}"
  probe_id                = "${azurerm_lb_probe.master.id}"
  protocol                       = "tcp"
  frontend_port                  = 443
  backend_port                   = 443
  idle_timeout_in_minutes        = 10
  frontend_ip_configuration_name = "default"
}

resource "azurerm_lb_probe" "master" {
  name                = "master-lb-probe-443-up"
  resource_group_name = "${data.azurerm_resource_group.ocp.name}"
  loadbalancer_id     = "${azurerm_lb.master.id}"
  protocol            = "Https"
  request_path        = "/healthz"
  port                = 443
}

resource "azurerm_network_security_group" "master" {
  name                = "ocp-master-security-group"
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
    name                        = "skydns"
    priority                    = 140
    direction                   = "Inbound"
    access                      = "Allow"
    protocol                    = "Udp"
    source_port_range           = "*"
    destination_port_range      = 8053
    source_address_prefix       = "VirtualNetwork"
    destination_address_prefix  = "*"
  }
  security_rule {
    name                        = "kubelet-proxy"
    priority                    = 150
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
    priority                    = 160
    direction                   = "Inbound"
    access                      = "Allow"
    protocol                    = "Tcp"
    source_port_range           = "*"
    destination_port_range      = 10010
    source_address_prefix       = "VirtualNetwork"
    destination_address_prefix  = "*"
  }
  security_rule {
    name                        = "etcd"
    priority                    = 170
    direction                   = "Inbound"
    access                      = "Allow"
    protocol                    = "Tcp"
    source_port_range           = "*"
    destination_port_range      = 2379
    source_address_prefix       = "VirtualNetwork"
    destination_address_prefix  = "*"
  }
  security_rule {
    name                        = "etcd-election"
    priority                    = 180
    direction                   = "Inbound"
    access                      = "Allow"
    protocol                    = "Tcp"
    source_port_range           = "*"
    destination_port_range      = 2380
    source_address_prefix       = "VirtualNetwork"
    destination_address_prefix  = "*"
  }
  security_rule {
    name                        = "node-exporter"
    priority                    = 190
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

resource "azurerm_network_interface" "master" {
  count                     = "${var.ocp_master_count}"
  name                      = "ocp-master-nic-${count.index + 1}"
  location                  = "${var.location}"
  resource_group_name       = "${data.azurerm_resource_group.ocp.name}"
  network_security_group_id = "${azurerm_network_security_group.master.id}"

  ip_configuration {
    name                                    = "default"
    subnet_id                               = "${data.azurerm_subnet.master.id}"
    private_ip_address_allocation           = "dynamic"
  }
}

resource "azurerm_virtual_machine" "master" {
  count                 = "${var.ocp_master_count}"
  name                  = "${var.ocp_cluster_prefix}-master-${count.index + 1}.${var.ocp_dns_zone_name}"
  location              = "${var.location}"
  resource_group_name   = "${data.azurerm_resource_group.ocp.name}"
  network_interface_ids = ["${element(azurerm_network_interface.master.*.id, count.index)}"]
  vm_size               = "${var.ocp_master_vm_size}"
  availability_set_id   = "${azurerm_availability_set.master.id}"

  storage_image_reference {
    id = "${var.ocp_os_image_ref}"
  }

  storage_os_disk {
    name              = "ocp-master-${count.index + 1}-os-disk"
    caching           = "ReadWrite"
    create_option     = "FromImage"
    managed_disk_type = "Standard_LRS"
  }

  delete_os_disk_on_termination    = true
  delete_data_disks_on_termination = true

  os_profile {
    computer_name  = "${var.ocp_cluster_prefix}-master-${count.index + 1}.${var.ocp_dns_zone_name}"
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

resource "azurerm_managed_disk" "master_docker_disk" {
  count                = "${var.ocp_master_count}"
  name                 = "${var.ocp_cluster_prefix}-master-${count.index + 1}-docker-disk"
  location             = "${var.location}"
  resource_group_name  = "${data.azurerm_dns_zone.ocp.resource_group_name}"
  storage_account_type = "Standard_LRS"
  create_option        = "Empty"
  disk_size_gb         = "${var.ocp_docker_disk_size}"
}
resource "azurerm_virtual_machine_data_disk_attachment" "master_docker_disk" {
  count              = "${var.ocp_master_count}"
  managed_disk_id    = "${element(azurerm_managed_disk.master_docker_disk.*.id, count.index)}"
  virtual_machine_id = "${element(azurerm_virtual_machine.master.*.id, count.index)}"
  lun                = 0
  caching            = "ReadWrite"
}

resource "azurerm_managed_disk" "master_emptydir_disk" {
  count                = "${var.ocp_master_count}"
  name                 = "${var.ocp_cluster_prefix}-master-${count.index + 1}-emptydir-disk"
  location             = "${var.location}"
  resource_group_name  = "${data.azurerm_dns_zone.ocp.resource_group_name}"
  storage_account_type = "Standard_LRS"
  create_option        = "Empty"
  disk_size_gb         = "${var.ocp_emptydir_disk_size}"
}
resource "azurerm_virtual_machine_data_disk_attachment" "master_emptydir_disk" {
  count              = "${var.ocp_master_count}"
  managed_disk_id    = "${element(azurerm_managed_disk.master_emptydir_disk.*.id, count.index)}"
  virtual_machine_id = "${element(azurerm_virtual_machine.master.*.id, count.index)}"
  lun                = 1
  caching            = "ReadWrite"
}

resource "azurerm_managed_disk" "master_etcd_disk" {
  count                = "${var.ocp_master_count}"
  name                 = "${var.ocp_cluster_prefix}-master-${count.index + 1}-etcd-disk"
  location             = "${var.location}"
  resource_group_name  = "${data.azurerm_dns_zone.ocp.resource_group_name}"
  storage_account_type = "Standard_LRS"
  create_option        = "Empty"
  disk_size_gb         = "${var.ocp_etcd_disk_size}"
}
resource "azurerm_virtual_machine_data_disk_attachment" "master_etcd_disk" {
  count              = "${var.ocp_master_count}"
  managed_disk_id    = "${element(azurerm_managed_disk.master_etcd_disk.*.id, count.index)}"
  virtual_machine_id = "${element(azurerm_virtual_machine.master.*.id, count.index)}"
  lun                = 2
  caching            = "ReadWrite"
}

resource "azurerm_dns_a_record" "ocp-master" {
  count               = "${var.ocp_master_count}"
  name                = "${var.ocp_cluster_prefix}-master-${count.index + 1}"
  zone_name           = "${data.azurerm_dns_zone.ocp.name}"
  resource_group_name = "${data.azurerm_dns_zone.ocp.resource_group_name}"
  ttl                 = 300
  records             = ["${element(azurerm_network_interface.master.*.private_ip_address, count.index)}"]
}
