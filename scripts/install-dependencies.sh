#!/usr/bin/env bash
git config --global user.name mhallin2
git config --global user.email mhallin2@volvocars.com
mkdir -p /workspaces/github/mhallin2
ansible-galaxy collection install azure.azcollection
pip3 install -r ~/.ansible/collections/ansible_collections/azure/azcollection/requirements.txt --no-input
# curl -fsSL https://aka.ms/install-azd.sh | bash
# azd auth login
dnf install azure-cli -y
az config set core.login_experience_v2=off
az login
git clone https://github.com/mhallin2/Hosting-Ansible-Playbooks /workspaces/github/mhallin2/Hosting-Ansible-Playbooks
git clone https://github.com/mhallin2/Hosting-Ansible-Collections /workspaces/github/mhallin2/Hosting-Ansible-Collections
/bin/bash "/workspaces/ansible-dev-tools/scripts/update-ansible-config.sh"
ansible-galaxy collection install -r /workspaces/github/mhallin2/Hosting-Ansible-Playbooks/requirements.yml
