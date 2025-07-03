git config --global user.name mhallin2
git config --global user.email mhallin2@volvocars.com
mkdir -p /workspaces/github/mhallin2
#git clone https://github.com/mhallin2/Hosting-Ansible-Playbooks /workspaces/github/mhallin2/Hosting-Ansible-Playbooks
cd /workspaces/github/mhallin2/Hosting-Ansible-Playbooks
ansible-galaxy collection install -r requirements.yml
