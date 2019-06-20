variable "resource_group_name" {
  description = "Resource Group name"
  default = "ocp"
  type = string
}

variable "location" {
  description = "Location in Azure"
  default = "West Europe"
  type = string
}
variable "ocp_master_count" {
  description = "Amount of masters - must be 3 or 5"
  default = 3
  type = string
}
variable "ocp_master_vm_size" {
  description = "Size of master VM"
  default = "Standard_E2s_v3"
  type = string
}

variable "ocp_os_image_ref" {
  description = "Azure Reference of the OS image to use"
  type = string
}

variable "ocp_vm_admin_user" {
  description = "Username on the VMs to be used"
  default = "ocpadmin"
  type = string
}

variable "ocp_cluster_prefix" {
  description = "Cluster Prefix name"
  default = "ocp01"
  type = string
}

variable "ocp_dns_zone_name" {
  description = "DNS Zone for nodes and OCP"
  type = string
}
variable "ocp_dns_base" {
  description = "DNS base for OCP domains (api/apps)"
  type = string
  default = ""
}
variable "ocp_node_dns_suffix" {
  description = "DNS suffix for node dns entries"
  type = string
  default = ""
}

variable "ocpvnet_name" {
  description = "Name of the ocpvnet"
  default = "ocpvnet"
  type = string
}

variable "ocpvnet_master_subnet_name" {
  description = "Name of the subnet for masters"
  default = "ocpvnet-master"
  type = string
}
variable "ocpvnet_node_subnet_name" {
  description = "Name of the subnet for nodes"
  default = "ocpvnet-node"
  type = string
}
variable "ocpvnet_addr_space" {
  description = "Overall network space"
  default = ["172.17.0.0/16"]
  type = list
}
variable "ocpvnet_master_subnet" {
  description = "The subnet for masters"
  default = "172.17.80.0/22"
  type = string
}
variable "ocpvnet_node_subnet" {
  description = "The subnet for nodes"
  default = "172.17.84.0/22"
  type = string
}
variable "ocp_bastion_vm_size" {
  description = "Size of master VM"
  default = "Standard_D2s_v3"
  type = string
}
variable "rh_activation_key" {
  description = "Activation Key for your subs"
  type = string
}
variable "rh_org" {
  description = "Organization in your satellite"
  type = string
}
variable "rh_pool_id" {
  description = "PoolID for your nodes"
  type = string
}
variable "rh_infra_pool_id" {
  description = "PoolID for your infra/master nodes"
  type = string
}

variable "ocp_infra_count" {
  description = "Amount of infra nodes"
  default = 2
  type = string
}
variable "ocp_infra_vm_size" {
  description = "Size of infra VM"
  default = "Standard_D4s_v3"
  type = string
}
variable "ocp_node_count" {
  description = "Amount of application nodes"
  default = 2
  type = string
}
variable "ocp_node_vm_size" {
  description = "Size of node VM"
  default = "Standard_DS12_v2"
  type = string
}

variable "ocp_docker_disk_size" {
  description = "Size of the docker disk"
  default = "128"
  type = string
}
variable "ocp_emptydir_disk_size" {
  description = "Size of the emptydir disk"
  default = "128"
  type = string
}
variable "ocp_etcd_disk_size" {
  description = "Size of the etcd disk"
  default = "40"
  type = string
}

variable "ocp_oreg_user" {
  description = "User for the OpenShift Registry"
  type = string
}
variable "ocp_oreg_password" {
  description = "Password for the OpenShift Registry"
  type = string
}

variable "ocp_openshift_docker_options" {
  description = "Additional options for docker"
  default=" --bip=10.86.0.100/16"
  type = string
}

variable "ocp_osm_host_subnet_length" {
  description = "Subnet Length"
  default="8"
  type = string
}
variable "ocp_osm_cluster_network_cidr" {
  description = "The network for the cluster"
  default="10.85.0.0/16"
  type = string
}
variable "ocp_openshift_portal_net" {
  description = "The network for the service network"
  default="10.84.0.0/16"
  type = string
}

variable "ocp_disk_storage_plan" {
  description = "The plan to use for data disks"
  default = "Standard_LRS"
  type = string
}
variable "ocp_pv_storage_plan" {
  description = "The plan to use for PVs"
  default = "Standard_LRS"
  type = string
}
