#!/bin/bash -e

cd $(dirname $0)

if [ ! -d ".terraform" ]; then
    echo "Initializing Terraform..."
    terraform init
fi

echo "Synchronizing Terraform state..."
terraform refresh -var-file=../ocp.tfvars

echo "Planning Terraform changes..."
terraform plan -out ocp.plan -var-file=../ocp.tfvars

echo "Deploying Terraform plan..."
terraform apply ocp.plan

