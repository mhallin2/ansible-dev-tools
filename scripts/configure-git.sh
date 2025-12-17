#!/usr/bin/env bash

# # Configure git
git config --global user.name mhallin2
git config --global user.email mhallin2@volvocars.com
# mkdir -p /workspaces/github/mhallin2
# mkdir -p /workspaces/github/volvo-cars
# git clone https://github.com/mhallin2/Hosting-Ansible-Playbooks /workspaces/github/mhallin2/Hosting-Ansible-Playbooks
# git clone https://github.com/mhallin2/Hosting-Ansible-Collections /workspaces/github/mhallin2/Hosting-Ansible-Collections
# git clone https://github.com/volvo-cars/Hosting-Database-Playbooks /workspaces/github/volvo-cars/Hosting-Database-Playbooks
# git clone https://github.com/volvo-cars/Hosting-Ansible-Actions /workspaces/github/volvo-cars/Hosting-Ansible-Actions
# git clone https://github.com/volvo-cars/Hosting-Ansible-TestArea /workspaces/github/volvo-cars/Hosting-Ansible-TestArea
# git clone https://github.com/volvo-cars/Hosting-Ansible-DummyRepo /workspaces/github/volvo-cars/Hosting-Ansible-DummyRepo
# /bin/bash "/workspaces/ansible-dev-tools/scripts/update-ansible-config.sh"
# ansible-galaxy collection install -r /workspaces/github/mhallin2/Hosting-Ansible-Playbooks/requirements.yml
# ansible-galaxy collection install /workspaces/github/mhallin2/Hosting-Ansible-Playbooks/collections/hosting_internal
# pip install -r ~/.ansible/collections/ansible_collections/vmware/vmware/requirements.txt --no-input


# Configure git with user-specific settings
# This script sets up git configuration and clones necessary repositories

# Set default values if environment variables are not provided
GIT_USERNAME="${GIT_USERNAME:-mhallin2}"
GIT_EMAIL="${GIT_EMAIL:-mhallin2@volvocars.com}"
GITHUB_USER="${GITHUB_USER:-${GIT_USERNAME}}"
WORKSPACE_BASE="${WORKSPACE_BASE:-/workspaces/github/}"

# Validate required variables
if [[ -z "$GIT_USERNAME" || -z "$GIT_EMAIL" ]]; then
    echo "❌ Error: GIT_USERNAME and GIT_EMAIL must be set"
    echo "Usage: GIT_USERNAME=your-username GIT_EMAIL=your-email@volvocars.com $0"
    exit 1
fi

# Configure git with user-specific settings
echo "🔧 Configuring git for user: $GIT_USERNAME"
git config --global user.name "$GIT_USERNAME"
git config --global user.email "$GIT_EMAIL"

# Create workspace directories
echo "📁 Creating workspace directories..."
mkdir -p "$WORKSPACE_BASE/$GITHUB_USER"
# mkdir -p "$WORKSPACE_BASE/volvo-cars"

# Function to clone repository with error handling
clone_repository() {
    local RepoUrl="$1"
    local TargetDir="$2"
    local RepoName
    RepoName=$(basename "$RepoUrl" .git)

    if [[ -d "$TargetDir" ]]; then
        echo "📂 Repository $RepoName already exists, skipping..."
        return 0
    fi

    echo "📥 Cloning $RepoName..."
    if git clone "$RepoUrl" "$TargetDir"; then
        echo "✅ Successfully cloned $RepoName"
        return 0
    else
        echo "❌ Failed to clone $RepoUrl"
        return 1
    fi
}

# Clone personal repositories
echo "📥 Cloning personal repositories for $GITHUB_USER..."
clone_repository "https://github.com/$GITHUB_USER/Hosting-Ansible-Playbooks" "$WORKSPACE_BASE/$GITHUB_USER/Hosting-Ansible-Playbooks"
clone_repository "https://github.com/$GITHUB_USER/Hosting-Ansible-Collections" "$WORKSPACE_BASE/$GITHUB_USER/Hosting-Ansible-Collections"
# git clone https://github.com/mhallin2/Hosting-Ansible-Playbooks /workspaces/github/mhallin2/Hosting-Ansible-Playbooks
# git clone https://github.com/mhallin2/Hosting-Ansible-Collections /workspaces/github/mhallin2/Hosting-Ansible-Collections
clone_repository "https://github.com/$GITHUB_USER/Hosting-Database-Playbooks" "$WORKSPACE_BASE/$GITHUB_USER/Hosting-Database-Playbooks"
clone_repository "https://github.com/$GITHUB_USER/Hosting-Ansible-EE" "$WORKSPACE_BASE/$GITHUB_USER/Hosting-Ansible-EE"
# Clone organization repositories
echo "📥 Cloning Volvo Cars organization repositories..."
clone_repository "https://github.com/volvo-cars/Hosting-Database-Playbooks" "$WORKSPACE_BASE/volvo-cars/Hosting-Database-Playbooks"
# clone_repository "https://github.com/volvo-cars/Hosting-Ansible-Actions" "$WORKSPACE_BASE/volvo-cars/Hosting-Ansible-Actions"
# clone_repository "https://github.com/volvo-cars/Hosting-Ansible-TestArea" "$WORKSPACE_BASE/volvo-cars/Hosting-Ansible-TestArea"
clone_repository "https://github.com/volvo-cars/Hosting-Ansible-Collections" "$WORKSPACE_BASE/volvo-cars/Hosting-Ansible-Collections"
clone_repository "https://github.com/volvo-cars/Hosting-Database-Playbooks" "$WORKSPACE_BASE/volvo-cars/Hosting-Database-Playbooks"
clone_repository "https://github.com/volvo-cars/Hosting-Ansible-Playbooks" "$WORKSPACE_BASE/volvo-cars/Hosting-Ansible-Playbooks"

# Update ansible configuration
echo "⚙️ Updating Ansible configuration..."
/bin/bash "/workspaces/ansible-dev-tools/scripts/update-ansible-config.sh"

# Install ansible collections
echo "📦 Installing Ansible collections..."
ansible-galaxy collection install -r "$WORKSPACE_BASE/$GITHUB_USER/Hosting-Ansible-Playbooks/requirements.yml" --force
ansible-galaxy collection install "$WORKSPACE_BASE/$GITHUB_USER/Hosting-Ansible-Playbooks/collections/hosting_internal" --force

# Install python requirements
echo "🐍 Installing Python requirements..."
pip install -r ~/.ansible/collections/ansible_collections/vmware/vmware/requirements.txt --no-input

echo "✅ Git configuration and repository setup completed successfully! 🎉"
echo ""
echo "📋 Summary:"
echo "  👤 Git User: $GIT_USERNAME ($GIT_EMAIL)"
echo "  📁 Workspace: $WORKSPACE_BASE"
