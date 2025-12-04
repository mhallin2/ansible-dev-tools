#!/bin/bash
# Update resolv.conf
echo "🔄 Copying resolv.conf to /etc/resolv.conf..."
cp /workspaces/ansible-dev-tools/scripts/resolv.conf /etc/resolv.conf
WORKSPACE="/workspaces/ansible-dev-tools"
# Update system and install dependencies
echo "🔄 Updating system and installing dependencies..."
dnf install $(cat $WORKSPACE/bindep.txt) -y

# Install Ansible Collections and Python packages
ansible-galaxy collection install azure.azcollection
pip3 install -r ~/.ansible/collections/ansible_collections/azure/azcollection/requirements.txt --no-input
pip install -r $WORKSPACE/scripts/requirements.txt

# Install Azure CLI via pip to get the latest version
pip install azure-cli --upgrade
curl -fsSL https://aka.ms/install-azd.sh | bash
azd auth login --use-device-code
az config set core.login_experience_v2=off
# az login

# Install/Configure user related settings and dependencies
/bin/bash "$WORKSPACE/scripts/configure-git.sh"
/bin/bash "$WORKSPACE/scripts/setup-extras.sh"

echo "✅ All dependencies have been installed and configured successfully!"
