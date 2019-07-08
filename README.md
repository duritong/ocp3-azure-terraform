# OCP on Azure through Terraform

This installs an OCP 3.11 on Microsoft Azure. It assumes everything is hosted on Azure, including the DNS entries for your hosts and your installation.

The procedure includes getting certificates signed by let's encrypt and setting up all the necessary cron jobs to regenerate and redeploy certificates.

## Architecture

These manifests setup the following base line:

* 1 Resource Group
* 1 Network with 2 Subnets (master/infra & application nodes)
* 1 Bastion Host with public SSH Access (all mainteance is done through that host)
* 3 masters, 2 infra nodes & n - application nodes
* 1 API LB pointing to the masters (Port 443)
* 1 Apps LB pointing to the infra nodes (Port 80 & 443)

                             +                   +
               +             |                   |
               |          +--v--+           +----v-----+
       +------------------|     |-----------|          |---------------------------------+
       |       |      +---+ API |           |  Apps    +--------+                        |
       |  +----v----+ |   ++---++           +------+---+        |                        |
       |  |         | |    |   |                   |            |                        |
       |  | Bastion | |    |   |                +--v-----+   +--v-----+                  |
       |  +---------+ |    |   |                |        |   |        |                  |
       |              |    |   |                | Infra  |   | Infra  |                  |
       |       +------v-+  |+--v-----+          +--------+   +--------+                  |
       |       |        |  ||        |                                                   |
       |       | Master |  || Master |                                                   |
       |       +--------+  |+--------+                                                   |
       |                   |                                                             |
       |            +------v-+                                                           |
       |            |        |              +-------------+   +-------------+            |
       |            | Master |              |             |   |             |            |
       |            +--------+              |  App Node   |   |  App Node   |            |
       |                                    +-------------+   +-------------+            |
       +---------------------------------------------------------------------------------+


## Components / Configuration

* OCP with htpasswd Authentication and one Admin Account
* Service Broker
* OLM
* Monitoring, Metering & Logs
* Network Policy with default zero trust network approach incl. EgressNetworkPolicy

## General idea and steps

1. Provision all the necessary infrastructure through terraform in Azure (Resource Group, netowrk, DNS Entries, VMs, ...), including setup of bastion host
2. Prepare all the nodes using ansible
3. Run the Ansible deploy_cluster.yml
4. Run post-setup steps

# Prerequisits

* You must have a custom baked standard RHEL 7.6 image uploaded and consumeable within your Azure subscription. Read the RedHat KB Article (TODO URL) for instructions.
* You must have a DNS Zone hosted on Azure, this DNS zone will be used for VM entries, as well as for the OCP Apps

# Pre Setup steps

* cp ocp.tfvars.example ocp.tfvars
* Edit tfvars according to your env
* cd terraform && ./apply.sh
* ssh -i ssh/bastion ocpadmin@BASTION_IP
* Run the /usr/share/ansible/openshift-ansible/playbooks/deploy_cluster.yml playbook with the ansible command you got as output from the previous command (this includes AD ID etc.)

## TODO

* disable waa agent
* Azure osb integration
