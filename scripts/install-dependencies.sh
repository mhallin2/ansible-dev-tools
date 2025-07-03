git config --global user.name mhallin2
git config --global user.email mhallin2@volvocars.com
mkdir -p /workspaces/github/mhallin2
ansible-galaxy collection install azure.azcollection
pip3 install -r ~/.ansible/collections/ansible_collections/azure/azcollection/requirements.txt
# curl -fsSL https://aka.ms/install-azd.sh | bash
# azd auth login
dnf install azure-cli
az login
#git clone https://github.com/mhallin2/Hosting-Ansible-Playbooks /workspaces/github/mhallin2/Hosting-Ansible-Playbooks
#cd /workspaces/github/mhallin2/Hosting-Ansible-Playbooks
#ansible-galaxy collection install -r requirements.yml
