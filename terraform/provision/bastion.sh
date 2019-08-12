#!/bin/bash

echo $(date) " - Starting Bastion Prep Script"

activationkey=$1
org=$2
poolid=$3

AZUREDNS_SUBSCRIPTIONID=$4
AZUREDNS_TENANTID=$5
AZUREDNS_APPID=$6
AZUREDNS_CLIENTSECRET=$7

dns_base_name=$8

if [ -z $activationkey ] || [ -z $org ] || [ -z $poolid ]; then
  echo "Require 'activationkey org poolid' as parameters"
  exit 1
fi

echo $(date) " - Register host with Cloud Access Subscription"
sudo rm -f /etc/yum.repos.d/rh-cloud.repo
sudo subscription-manager register --force --activationkey="${activationkey}" --org="${org}"
RETCODE=$?

if [ $RETCODE -eq 0 ]
then
    echo "Subscribed successfully"
elif [ $RETCODE -eq 64 ]
then
    echo "This system is already registered."
else
    echo "Incorrect Username / Password or Organization ID / Activation Key specified"
    exit 3
fi

sudo subscription-manager attach --pool=$poolid > attach.log
if [ $? -eq 0 ]
then
    echo "Pool attached successfully"
else
    sudo grep attached attach.log
    if [ $? -eq 0 ]
    then
        echo "Pool $POOL_ID was already attached and was not attached again."
    else
        echo "Incorrect Pool ID or no entitlements available"
        sudo cat attach.log
        exit 4
    fi
fi

echo $(date) " - Disabling all repositories and enabling only the required repos"

sudo subscription-manager repos --disable="*"

sudo subscription-manager repos \
    --enable="rhel-7-server-rpms" \
    --enable="rhel-7-server-extras-rpms" \
    --enable="rhel-7-server-ose-3.11-rpms" \
    --enable="rhel-7-server-ansible-2.6-rpms" \
    --enable="rhel-7-fast-datapath-rpms" \

set -e

echo $(date) " - Update system to latest packages"
sudo yum -y update
echo $(date) " - System update complete"

echo $(date) " - Install base packages"
sudo yum -y install wget git net-tools bind-utils iptables-services bridge-utils bash-completion httpd-tools kexec-tools sos psacct ansible openshift-ansible atomic-openshift-clients tmux
echo $(date) " - Base package installation complete"

# Installing Azure CLI
# From https://docs.microsoft.com/en-us/cli/azure/install-azure-cli-yum
echo $(date) " - Installing Azure CLI"
sudo rpm --import https://packages.microsoft.com/keys/microsoft.asc
sudo sh -c 'echo -e "[azure-cli]\nname=Azure CLI\nbaseurl=https://packages.microsoft.com/yumrepos/azure-cli\nenabled=1\ngpgcheck=1\ngpgkey=https://packages.microsoft.com/keys/microsoft.asc" > /etc/yum.repos.d/azure-cli.repo'
sudo yum install -y azure-cli
echo $(date) " - Azure CLI installation complete"


# Configure DNS so it always has the domain name
echo $(date) " - Adding DOMAIN to search for resolv.conf"
echo "DOMAIN=`domainname -d`" | sudo tee -a /etc/sysconfig/network-scripts/ifcfg-eth0

chmod +x ~/ocp/*.sh

# configure acme.sh client
git clone https://github.com/Neilpang/acme.sh.git
cd acme.sh
./acme.sh --install --home ~/acme --config-home ~/ocp/acme/data --cert-home  ~/ocp/certs --accountkey  ~/ocp/acme/account.key

. ~/acme/acme.sh.env

# register domains
export AZUREDNS_SUBSCRIPTIONID
export AZUREDNS_TENANTID
export AZUREDNS_APPID
export AZUREDNS_CLIENTSECRET

~/acme/acme.sh --config-home ~/ocp/acme/data --issue --dns dns_azure -d "api${dns_base_name}" -d "api-int${dns_base_name}" --renew-hook ~/ocp/acme-renew-hook-master.sh
~/acme/acme.sh --config-home ~/ocp/acme/data --issue --dns dns_azure -d "apps${dns_base_name}" -d "*.apps${dns_base_name}" --renew-hook ~/ocp/acme-renew-hook-router.sh

cd ~/ocp
git init
git config user.name "Bastion api${dns_base_name}"
git config user.email "bastion@api${dns_base_name}"
git add .
git commit -a -m "initial commit of cluster @ api${dns_base_name}"

echo $(date) " - Script Complete"
