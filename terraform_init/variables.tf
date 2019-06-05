variable "resource_group_name" {
  description = "Resource Group name"
  default = "ocp"
  type = "string"
}

variable "location" {
  description = "Location in Azure"
  default = "West Europe"
  type = "string"
}

variable "ocpvnet_name" {
  description = "Name of the ocpvnet"
  default = "ocpvnet"
  type = "string"
}

variable "ocpvnet_addr_space" {
  description = "Overall network space"
  default = ["172.17.0.0/16"]
  type = "list"
}
variable "ocpvnet_master_subnet_name" {
  description = "Name of the subnet for masters"
  default = "ocpvnet-master"
  type = "string"
}
variable "ocpvnet_master_subnet" {
  description = "The subnet for masters"
  default = "172.17.80.0/22"
  type = "string"
}

variable "ocpvnet_node_subnet_name" {
  description = "Name of the subnet for nodes"
  default = "ocpvnet-node"
  type = "string"
}
variable "ocpvnet_node_subnet" {
  description = "The subnet for nodes"
  default = "172.17.84.0/22"
  type = "string"
}

variable "ocp_dns_zone_name" {
  description = "DNS Zone for nodes and OCP"
  type = "string"
}
