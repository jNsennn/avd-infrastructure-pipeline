# Azure Virtual Desktop (AVD) Infrastructure with Packer, Ansible & Terraform

This repository provides a complete Infrastructure as Code (IaC) solution for Azure Virtual Desktop (AVD) deployment using Packer for custom image building, Ansible for configuration management, and Terraform for infrastructure provisioning.

## 🏗️ Architecture Overview

```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│     Packer      │    │     Ansible     │    │    Terraform    │
│  Image Builder  │────│  Configuration  │────│  Infrastructure │
│                 │    │   Management    │    │   Provisioning  │
└─────────────────┘    └─────────────────┘    └─────────────────┘
        │                        │                        │
        ▼                        ▼                        ▼
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│ Custom Windows  │    │ Security &      │    │ AVD Host Pool   │
│ 11 AVD Images   │    │ Software Setup  │    │ & Session Hosts │
└─────────────────┘    └─────────────────┘    └─────────────────┘
```

## 🚀 Features

- **Automated Image Building**: Weekly custom Windows 11 AVD images with latest updates
- **Security Hardening**: SMB signing, disable SMBv1, LLMNR/mDNS protection
- **Software Management**: Chocolatey package management with essential tools
- **Cost Optimization**: Auto-shutdown schedules and disk cleanup
- **CI/CD Integration**: GitHub Actions workflows for full automation
- **Infrastructure as Code**: Complete Terraform configuration following Microsoft patterns

## 📋 Prerequisites

### Azure Requirements
- Azure subscription with sufficient permissions
- **Required Azure Resource Providers** (register these in your subscription):
  ```bash
  az provider register --namespace Microsoft.Storage
  az provider register --namespace Microsoft.Compute
  az provider register --namespace Microsoft.Network
  az provider register --namespace Microsoft.DesktopVirtualization
  ```

### Local Development Tools
- [Terraform](https://www.terraform.io/downloads.html) >= 1.0
- [Packer](https://www.packer.io/downloads) >= 1.8
- [Ansible](https://docs.ansible.com/ansible/latest/installation_guide/intro_installation.html) >= 6.0
- [Azure CLI](https://docs.microsoft.com/en-us/cli/azure/install-azure-cli) >= 2.40
- Python 3.8+ with `pywinrm` and `requests` modules

### Azure Service Principal
Create a service principal with appropriate permissions for Packer, Terraform, and AVD management:

```bash
# Create service principal
az ad sp create-for-rbac --name "avd-automation" --role "Contributor" --scopes "/subscriptions/YOUR_SUBSCRIPTION_ID"

# Additional role assignments for AVD
az role assignment create --assignee "SERVICE_PRINCIPAL_ID" --role "Desktop Virtualization Contributor" --scope "/subscriptions/YOUR_SUBSCRIPTION_ID"
```

## 🔧 Setup & Configuration

### 1. Clone and Configure

```bash
git clone <repository-url>
cd azure-avd-infrastructure
```

### 2. Set Environment Variables

```bash
# Azure Authentication
export ARM_SUBSCRIPTION_ID="your-subscription-id"
export ARM_TENANT_ID="your-tenant-id"
export ARM_CLIENT_ID="your-client-id"
export ARM_CLIENT_SECRET="your-client-secret"

# Terraform Variables
export TF_VAR_admin_password="YourSecurePassword123!"

# Packer Variables (for local builds)
export PKR_VAR_subscription_id="your-subscription-id"
export PKR_VAR_tenant_id="your-tenant-id"
export PKR_VAR_client_id="your-client-id"
export PKR_VAR_client_secret="your-client-secret"
export PKR_VAR_resource_group_name="your-packer-resource-group"
```

### 3. Configure Terraform Backend

1. Create an Azure Storage Account for Terraform state:
```bash
# Create resource group
az group create --name "rg-terraform-state" --location "East US"

# Create storage account (name must be globally unique)
az storage account create \
  --resource-group "rg-terraform-state" \
  --name "tfstateYOURUNIQUEID" \
  --sku "Standard_LRS" \
  --encryption-services blob

# Create container
az storage container create \
  --name "tfstate" \
  --account-name "tfstateYOURUNIQUEID"
```

2. Update `terraform/backend.tf` with your storage account name:
```hcl
terraform {
  backend "azurerm" {
    resource_group_name  = "rg-terraform-state"
    storage_account_name = "tfstateYOURUNIQUEID"  # Your actual storage account name
    container_name       = "tfstate"
    key                  = "avd.tfstate"
  }
}
```

### 4. Customize Configuration

Edit `terraform/terraform.tfvars` to match your requirements:

```hcl
# Resource Configuration
resource_group_name = "rg-avd"
location           = "East US"

# Session Host Configuration
rdsh_count = 2
prefix     = "avd"

# VM Configuration
vm_size        = "Standard_B2ms"
admin_username = "avdadmin"

# Custom Image Configuration
avd_image_name              = ""  # Leave empty for latest
avd_image_resource_group    = "rg-packer-build"

# Networking Configuration
vnet_address_space     = ["10.0.0.0/16"]
subnet_address_prefix  = "10.0.1.0/24"
```

## 🛠️ Usage

### Option 1: GitHub Actions (Recommended)

1. **Setup GitHub Secrets**:
   - `AZURE_CLIENT_ID`
   - `AZURE_CLIENT_SECRET`
   - `AZURE_SUBSCRIPTION_ID`
   - `AZURE_TENANT_ID`
   - `AZURE_RESOURCE_GROUP` (for Packer builds)
   - `AVD_ADMIN_PASSWORD`

2. **Trigger Workflows**:
   - **Weekly Image Build**: Runs automatically every Sunday at 2 AM UTC
   - **Manual Trigger**: Go to Actions → "Weekly AVD Image Update" → "Run workflow"
   - **Host Pool Update**: Runs automatically after successful image build

### Option 2: Local Deployment

1. **Build Custom Image** (Optional):
```bash
cd packer
packer init .
packer build .
```

2. **Deploy Infrastructure**:
```bash
cd terraform
terraform init
terraform plan
terraform apply
```

3. **Assign User Permissions**:
```bash
# Replace with actual user email
USER_EMAIL="user@yourdomain.com"
USER_ID=$(az ad user show --id "$USER_EMAIL" --query "id" --output tsv)

# Assign Desktop Virtualization User role
az role assignment create \
  --assignee "$USER_ID" \
  --role "Desktop Virtualization User" \
  --scope "/subscriptions/$ARM_SUBSCRIPTION_ID/resourceGroups/rg-avd/providers/Microsoft.DesktopVirtualization/applicationGroups/dag-desktop"

# Assign VM User Login role
az role assignment create \
  --assignee "$USER_ID" \
  --role "Virtual Machine User Login" \
  --scope "/subscriptions/$ARM_SUBSCRIPTION_ID/resourceGroups/rg-avd"
```

## 📁 Project Structure

```
├── .github/workflows/          # GitHub Actions CI/CD
│   ├── weekly-avd-image-update.yml
│   └── update-avd-hostpool.yml
├── ansible/                    # Configuration management
│   ├── playbooks/
│   │   ├── mainplaybook.yml    # Full image configuration
│   │   └── update-playbook.yml # Incremental updates
│   ├── vars/                   # Configuration variables
│   └── requirements.yml        # Ansible collections
├── packer/                     # Image building
│   ├── build.pkr.hcl          # Build configurations
│   ├── source.pkr.hcl         # Azure ARM sources
│   ├── variables.pkr.hcl      # Variable definitions
│   └── vars.auto.pkrvars.hcl  # Variable values
└── terraform/                  # Infrastructure provisioning
    ├── main.tf                 # Main infrastructure
    ├── variables.tf            # Variable definitions
    ├── outputs.tf              # Output values
    ├── terraform.tfvars        # Variable values
    └── backend.tf              # State backend config
```

## 🔒 Security Features

### Windows Security Hardening
- **SMB Security**: Enforce SMB signing, disable SMBv1
- **Network Security**: Disable LLMNR, mDNS, NetBIOS over TCP/IP
- **Authentication**: Remove auto-logon settings
- **Updates**: Automated Windows Update configuration

### Network Security
- **NSG Rules**: Restrict RDP access to deployment IP only
- **Private Networking**: Session hosts on private subnet
- **Azure AD Join**: Modern authentication with conditional access support

### Monitoring & Compliance
- **Auto-shutdown**: Cost optimization with scheduled shutdowns
- **Tagging**: Comprehensive resource tagging for governance
- **Image Tracking**: Build information and source tracking

## 🔧 Customization

### Adding Software Packages
Edit `ansible/playbooks/mainplaybook.yml` to add software via Chocolatey:

```yaml
- name: "Install additional software"
  ansible.windows.win_powershell:
    script: |
      choco install googlechrome --yes --limit-output
      choco install vscode --yes --limit-output
```

### Modifying Security Settings
Edit `ansible/vars/securitysettings.yml` to customize registry settings:

```yaml
Your_Custom_Setting:
  reg_path: HKLM:\Your\Registry\Path
  reg_name: YourSettingName
  reg_data: 1
  reg_type: dword
  reg_state: present
```

### Scaling Configuration
Modify `terraform/terraform.tfvars`:
- `rdsh_count`: Number of session hosts
- `vm_size`: VM size for session hosts
- `maximum_sessions_allowed`: Users per session host

## 🚨 Important Notes

### Microsoft Entra ID Security Defaults
If your tenant has Security Defaults enabled, new AVD sessions may fail to authenticate. Consider your security requirements:
- **Disable Security Defaults**: For simplified AVD access
- **Configure Conditional Access**: For advanced security policies

Learn more: [Security Defaults Documentation](https://learn.microsoft.com/en-us/entra/fundamentals/security-defaults)

### Cost Management
- **Auto-shutdown**: Configured for 7 PM Central European Time
- **Image Cleanup**: Automatically removes images older than 28 days
- **Storage Optimization**: Standard LRS storage for cost savings

### Resource Naming
This configuration creates resources with generic names. For production environments, consider:
- Updating resource naming conventions
- Adding environment-specific prefixes
- Implementing proper tagging strategies

## 🐛 Troubleshooting

### Common Issues

1. **Packer Build Fails**:
   - Check WinRM connectivity
   - Verify Azure credentials and permissions
   - Review Ansible playbook errors in logs

2. **Terraform Plan Fails**:
   - Ensure backend storage account exists
   - Verify service principal permissions
   - Check resource provider registrations

3. **AVD Connection Issues**:
   - Verify user role assignments
   - Check NSG rules for RDP access
   - Confirm Azure AD join status

4. **GitHub Actions Failures**:
   - Verify all secrets are set correctly
   - Check workflow permissions
   - Review action logs for specific errors