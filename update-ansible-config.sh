#!/bin/bash
# Description: Fetch AAP Hub token from Azure Key Vault and update ansible.cfg
# Usage: ./update-ansible-config.sh
# Prerequisites: Azure CLI must be installed and authenticated (az login)

set -euo pipefail

# Configuration variables following project PascalCase standards
readonly Config_File_Path="/workspaces/ansible-dev-tools/scripts/ansible.cfg"
readonly Keyvault_Name="kv-weu-wintel-prod"
readonly Secret_Name="APIkey-Private-AAP-HUB"
readonly Secret_Version="6024959f4bec42c4a2500bc31317116d"
readonly Token_Placeholder="{{Hub_token}}"

# Color codes for output
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    local color=$1
    local message=$2
    echo -e "${color}${message}${NC}"
}

# Function to validate prerequisites
validate_prerequisites() {
    print_status "$YELLOW" "🔍 Validating prerequisites..."

    # Check if Azure CLI is installed
    if ! command -v az &> /dev/null; then
        print_status "$RED" "❌ Azure CLI is not installed. Please install it first."
        exit 1
    fi

    # Check if user is logged in to Azure
    if ! az account show &> /dev/null; then
        print_status "$RED" "❌ Not logged in to Azure. Please run 'az login' first."
        exit 1
    fi

    # Check if ansible.cfg file exists
    if [[ ! -f "$Config_File_Path" ]]; then
        print_status "$RED" "❌ Ansible config file not found: $Config_File_Path"
        exit 1
    fi

    print_status "$GREEN" "✅ Prerequisites validated successfully"
}

# Function to fetch secret from Azure Key Vault
fetch_keyvault_secret() {
    print_status "$YELLOW" "🔐 Fetching AAP Hub token from Azure Key Vault..."

    local hub_token
    hub_token=$(az keyvault secret show \
        --vault-name "$Keyvault_Name" \
        --name "$Secret_Name" \
        --version "$Secret_Version" \
        --query "value" \
        --output tsv 2>/dev/null)

    if [[ -z "$hub_token" ]]; then
        print_status "$RED" "❌ Failed to fetch secret from Azure Key Vault"
        print_status "$RED" "   Vault: https://${Keyvault_Name}.vault.azure.net/"
        print_status "$RED" "   Secret: ${Secret_Name}"
        print_status "$RED" "   Version: ${Secret_Version}"
        exit 1
    fi

    print_status "$GREEN" "✅ Successfully retrieved AAP Hub token from Azure Key Vault"
    echo "$hub_token"
}

# Function to update ansible.cfg with the token
update_ansible_config() {
    local hub_token=$1

    print_status "$YELLOW" "📝 Updating ansible.cfg with AAP Hub token..."

    # Create backup of original file
    local backup_file
    backup_file="${Config_File_Path}.backup.$(date +%Y%m%d_%H%M%S)"
    cp "$Config_File_Path" "$backup_file"
    print_status "$GREEN" "📋 Backup created: $backup_file"

    # Replace token placeholder with actual token
    if sed -i "s|${Token_Placeholder}|${hub_token}|g" "$Config_File_Path"; then
        print_status "$GREEN" "✅ Successfully updated ansible.cfg with AAP Hub token"
    else
        print_status "$RED" "❌ Failed to update ansible.cfg"
        # Restore backup
        cp "$backup_file" "$Config_File_Path"
        print_status "$YELLOW" "🔄 Restored original configuration from backup"
        exit 1
    fi
}

# Function to verify the update
verify_update() {
    print_status "$YELLOW" "🔍 Verifying configuration update..."

    # Check if placeholder still exists (should not)
    if grep -q "$Token_Placeholder" "$Config_File_Path"; then
        print_status "$RED" "❌ Token placeholder still found in configuration file"
        exit 1
    fi

    # Check if token lines exist (should have actual tokens now)
    local token_count
    token_count=$(grep -c "^token=" "$Config_File_Path" || true)

    if [[ "$token_count" -eq 0 ]]; then
        print_status "$RED" "❌ No token configurations found in ansible.cfg"
        exit 1
    fi

    print_status "$GREEN" "✅ Configuration verification successful"
    print_status "$GREEN" "📊 Found $token_count token configurations in ansible.cfg"
}

# Main execution function
main() {
    print_status "$GREEN" "🚀 Starting AAP Hub token configuration update..."
    echo

    validate_prerequisites
    echo

    local hub_token
    hub_token=$(fetch_keyvault_secret)
    echo

    update_ansible_config "$hub_token"
    echo

    verify_update
    echo

    print_status "$GREEN" "🎉 Ansible configuration successfully updated with AAP Hub token!"
    print_status "$GREEN" "📁 Configuration file: $Config_File_Path"
    print_status "$GREEN" "🔗 All galaxy server configurations now have valid tokens"
}

# Execute main function
main "$@"
