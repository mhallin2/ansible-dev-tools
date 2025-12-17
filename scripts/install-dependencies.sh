#!/bin/bash
# Update resolv.conf
echo "🔄 Copying resolv.conf to /etc/resolv.conf..."
cp /workspaces/ansible-dev-tools/scripts/resolv.conf /etc/resolv.conf
WORKSPACE="/workspaces/ansible-dev-tools"
# Update system and install dependencies
echo "🔄 Updating system and installing dependencies..."
yum upgrade -y
yum install $(cat $WORKSPACE/bindep.txt) -y

# Install Ansible Collections and Python packages
ansible-galaxy collection install azure.azcollection==3.12.0 --collections-path /root/.ansible/collections/ansible_collections/
pip3 install -r /root/.ansible/collections/ansible_collections/azure/azcollection/requirements.txt --no-input
pip install -r $WORKSPACE/scripts/requirements.txt

# Install Azure CLI via pip to get the latest version
pip install azure-cli==2.75
curl -fSL https://github.com/Azure/azure-dev/releases/download/azure-dev-cli_1.22.3/azd-1.22.3-1.x86_64.rpm -o /tmp/azd-1.22.3-1.x86_64.rpm
yum install -y /tmp/azd-1.22.3-1.x86_64.rpm
# azd auth login
az config set core.login_experience_v2=off
az login

# Install/Configure user related settings and dependencies
/bin/bash "$WORKSPACE/scripts/configure-git.sh"
/bin/bash "$WORKSPACE/scripts/setup-extras.sh"

echo "✅ All dependencies have been installed and configured successfully!"
