#!/usr/bin/env python3
"""
Description: Fetch AAP Hub token from Azure Key Vault and update ansible.cfg
Usage: python3 update-ansible-config.py
Prerequisites: Azure CLI must be installed and authenticated (az login)
              OR Azure identity libraries with proper authentication
"""

import os
import sys
import shutil
import subprocess
import re
from datetime import datetime
from pathlib import Path
from typing import Optional

try:
    from azure.keyvault.secrets import SecretClient
    from azure.identity import DefaultAzureCredential
    AZURE_SDK_AVAILABLE = True
except ImportError:
    AZURE_SDK_AVAILABLE = False

# Configuration variables following project PascalCase standards
Config_File_Path = "/workspaces/ansible-dev-tools/scripts/ansible.cfg"
Keyvault_Name = "kv-weu-wintel-prod"
Secret_Name = "APIkey-Private-AAP-HUB"
Secret_Version = "6024959f4bec42c4a2500bc31317116d"
Token_Placeholder = "Hub_Token"

# Color codes for output
class Colors:
    """Color codes for terminal output"""
    RED = '\033[0;31m'
    GREEN = '\033[0;32m'
    YELLOW = '\033[1;33m'
    NC = '\033[0m'  # No Color

def print_status(color: str, message: str) -> None:
    """Print colored status message to console

    Args:
        color: Color code from Colors class
        message: Status message to display
    """
    print(f"{color}{message}{Colors.NC}")

def validate_prerequisites() -> None:
    """Validate all prerequisites before execution

    Raises:
        SystemExit: If any prerequisite validation fails
    """
    print_status(Colors.YELLOW, "🔍 Validating prerequisites...")

    # Check if Azure CLI is installed
    try:
        subprocess.run(['az', '--version'],
                      capture_output=True,
                      check=True,
                      timeout=10)
    except (subprocess.CalledProcessError, FileNotFoundError, subprocess.TimeoutExpired):
        print_status(Colors.RED, "❌ Azure CLI is not installed. Please install it first.")
        sys.exit(1)

    # Check if user is logged in to Azure (if using CLI method)
    if not AZURE_SDK_AVAILABLE:
        try:
            subprocess.run(['az', 'account', 'show'],
                          capture_output=True,
                          check=True,
                          timeout=10)
        except (subprocess.CalledProcessError, subprocess.TimeoutExpired):
            print_status(Colors.RED, "❌ Not logged in to Azure. Please run 'az login' first.")
            sys.exit(1)

    # Check if ansible.cfg file exists
    Config_File = Path(Config_File_Path)
    if not Config_File.exists():
        print_status(Colors.RED, f"❌ Ansible config file not found: {Config_File_Path}")
        sys.exit(1)

    print_status(Colors.GREEN, "✅ Prerequisites validated successfully")

def fetch_keyvault_secret_sdk() -> str:
    """Fetch secret using Azure SDK

    Returns:
        str: The secret value from Azure Key Vault

    Raises:
        SystemExit: If secret retrieval fails
    """
    try:
        # Initialize Azure credential and Key Vault client
        Credential = DefaultAzureCredential()
        Vault_Url = f"https://{Keyvault_Name}.vault.azure.net/"
        Client = SecretClient(vault_url=Vault_Url, credential=Credential)

        # Retrieve the secret
        Secret = Client.get_secret(Secret_Name, version=Secret_Version)
        return Secret.value

    except Exception as e:
        print_status(Colors.RED, f"❌ Failed to fetch secret using Azure SDK: {str(e)}")
        print_status(Colors.RED, f"   Vault: https://{Keyvault_Name}.vault.azure.net/")
        print_status(Colors.RED, f"   Secret: {Secret_Name}")
        print_status(Colors.RED, f"   Version: {Secret_Version}")
        sys.exit(1)

def fetch_keyvault_secret_cli() -> str:
    """Fetch secret using Azure CLI as fallback

    Returns:
        str: The secret value from Azure Key Vault

    Raises:
        SystemExit: If secret retrieval fails
    """
    try:
        # Use Azure CLI to fetch the secret
        Result = subprocess.run([
            'az', 'keyvault', 'secret', 'show',
            '--vault-name', Keyvault_Name,
            '--name', Secret_Name,
            '--version', Secret_Version,
            '--query', 'value',
            '--output', 'tsv'
        ], capture_output=True, text=True, check=True, timeout=30)

        Hub_Token = Result.stdout.strip()
        if not Hub_Token:
            raise ValueError("Empty token received from Azure CLI")

        return Hub_Token

    except (subprocess.CalledProcessError, subprocess.TimeoutExpired, ValueError) as e:
        print_status(Colors.RED, f"❌ Failed to fetch secret using Azure CLI: {str(e)}")
        print_status(Colors.RED, f"   Vault: https://{Keyvault_Name}.vault.azure.net/")
        print_status(Colors.RED, f"   Secret: {Secret_Name}")
        print_status(Colors.RED, f"   Version: {Secret_Version}")
        sys.exit(1)

def fetch_keyvault_secret() -> str:
    """Fetch AAP Hub token from Azure Key Vault

    Returns:
        str: The AAP Hub token

    Raises:
        SystemExit: If token retrieval fails
    """
    print_status(Colors.YELLOW, "🔐 Fetching AAP Hub token from Azure Key Vault...")

    # Try Azure SDK first, fallback to CLI
    if AZURE_SDK_AVAILABLE:
        try:
            Hub_Token = fetch_keyvault_secret_sdk()
        except SystemExit:
            print_status(Colors.YELLOW, "🔄 Azure SDK failed, falling back to Azure CLI...")
            Hub_Token = fetch_keyvault_secret_cli()
    else:
        print_status(Colors.YELLOW, "📝 Azure SDK not available, using Azure CLI...")
        Hub_Token = fetch_keyvault_secret_cli()

    print_status(Colors.GREEN, "✅ Successfully retrieved AAP Hub token from Azure Key Vault")
    return Hub_Token

def update_ansible_config(Hub_Token: str) -> None:
    """Update ansible.cfg with the retrieved token

    Args:
        Hub_Token: The AAP Hub token to insert into configuration

    Raises:
        SystemExit: If configuration update fails
    """
    print_status(Colors.YELLOW, "📝 Updating ansible.cfg with AAP Hub token...")

    Config_File = Path(Config_File_Path)

    # Create backup of original file
    Timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
    Backup_File = Path(f"{Config_File_Path}.backup.{Timestamp}")

    try:
        shutil.copy2(Config_File, Backup_File)
        print_status(Colors.GREEN, f"📋 Backup created: {Backup_File}")
    except (OSError, IOError) as e:
        print_status(Colors.RED, f"❌ Failed to create backup: {str(e)}")
        sys.exit(1)

    # Read the configuration file
    try:
        with open(Config_File, 'r', encoding='utf-8') as file:
            Config_Content = file.read()
    except (OSError, IOError) as e:
        print_status(Colors.RED, f"❌ Failed to read configuration file: {str(e)}")
        sys.exit(1)

    # Escape special regex characters in the token
    Escaped_Token = re.escape(Hub_Token)

    # Replace token placeholder with actual token
    print_status(Colors.GREEN, "✅ Starting update of ansible.cfg with AAP Hub token")

    try:
        # Perform the replacement
        Updated_Content = Config_Content.replace(Token_Placeholder, Hub_Token)

        # Write the updated content back to the file
        with open(Config_File, 'w', encoding='utf-8') as file:
            file.write(Updated_Content)

        print_status(Colors.GREEN, "✅ Successfully updated ansible.cfg with AAP Hub token")

    except (OSError, IOError) as e:
        print_status(Colors.RED, f"❌ Failed to update ansible.cfg: {str(e)}")
        # Restore backup
        try:
            shutil.copy2(Backup_File, Config_File)
            print_status(Colors.YELLOW, "🔄 Restored original configuration from backup")
        except (OSError, IOError) as restore_error:
            print_status(Colors.RED, f"❌ Failed to restore backup: {str(restore_error)}")
        sys.exit(1)

def verify_update() -> None:
    """Verify that the configuration update was successful

    Raises:
        SystemExit: If verification fails
    """
    print_status(Colors.YELLOW, "🔍 Verifying configuration update...")

    Config_File = Path(Config_File_Path)

    try:
        with open(Config_File, 'r', encoding='utf-8') as file:
            Config_Content = file.read()
    except (OSError, IOError) as e:
        print_status(Colors.RED, f"❌ Failed to read configuration file for verification: {str(e)}")
        sys.exit(1)

    # Check if placeholder still exists (should not)
    if Token_Placeholder in Config_Content:
        print_status(Colors.RED, "❌ Token placeholder still found in configuration file")
        sys.exit(1)

    # Check if token lines exist (should have actual tokens now)
    Token_Count = len(re.findall(r'^token=', Config_Content, re.MULTILINE))

    if Token_Count == 0:
        print_status(Colors.RED, "❌ No token configurations found in ansible.cfg")
        sys.exit(1)

    print_status(Colors.GREEN, "✅ Configuration verification successful")
    print_status(Colors.GREEN, f"📊 Found {Token_Count} token configurations in ansible.cfg")

def main() -> None:
    """Main execution function"""
    print_status(Colors.GREEN, "🚀 Starting AAP Hub token configuration update...")
    print()

    try:
        validate_prerequisites()
        print()

        Hub_Token = fetch_keyvault_secret()
        print()

        update_ansible_config(Hub_Token)
        print()

        verify_update()
        print()

        print_status(Colors.GREEN, "🎉 Ansible configuration successfully updated with AAP Hub token!")
        print_status(Colors.GREEN, f"📁 Configuration file: {Config_File_Path}")
        print_status(Colors.GREEN, "🔗 All galaxy server configurations now have valid tokens")

    except KeyboardInterrupt:
        print_status(Colors.YELLOW, "\n🛑 Operation cancelled by user")
        sys.exit(1)
    except Exception as e:
        print_status(Colors.RED, f"❌ Unexpected error: {str(e)}")
        sys.exit(1)

if __name__ == "__main__":
    main()
