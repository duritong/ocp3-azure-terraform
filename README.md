# OCP on Azure through Terraform

This installs an OCP 3.11 enterprise on Microsoft Azure. It assumes everything is hosted on Azure, including the DNS entries for your hosts and your installation.

## General idea and steps

1. Create the Azure Resource Group & networks which will host openshift. This might have been done through other setup steps.
2. Create all the necessary resources (including DNS entries) to setup your cluster & prepare the nodes
3. Run the Ansible deploy_cluster.yml
4. Run post-setup steps (TODO)

# Prerequisits

* You must have a custom baked standard RHEL 7.6 image uploaded and consumeable within your Azure subscription. Read the RedHat KB Article (TODO URL) for instructions.
* You must have a DNS Zone hosted on Azure, this DNS zone will be used for VM entries, as well as for the OCP Apps

# Pre Setup steps

* cp ocp.tfvars.example ocp.tfvars
* Edit tfvars according to your env
* mkdir certs
* ssh-keygen -t rsa -b 4096 -f certs/bastion -N '
* ssh-keygen -t rsa -b 4096 -f certs/openshift -N '
* cd terraform_init && ./apply.sh (OPTIONAL if you need to setup ResourceGroup etc.)
* cd terraform && ./apply.sh
* ssh -i certs/bastion ocpadmin@BASTION_IP
* Run the /usr/share/ansible/openshift-ansible/playbooks/deploy_cluster.yml playbook with the ansible command you got as output from the previous command (this includes AD ID etc.)

## TODO

* Investigate Any RULE for 443 on master and LB
* Let's Encrypt certificates
