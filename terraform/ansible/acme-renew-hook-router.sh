#!/bin/bash

cd ~/ocp
ansible-playbook /usr/share/ansible/openshift-ansible/playbooks/openshift-hosted/redeploy-router-certificates.yml
