# Opella Infrastructure - Azure with Terraform

Infrastructure as Code (IaC) for provisioning Azure resources using Terraform, with a reusable VNET module and multi-environment support.

## Repository Structure

```
.
├── modules/
│   └── vnet/                  # Reusable VNET module
│       ├── main.tf            # VNET, subnets, NSGs, NSG rules
│       ├── variables.tf       # Module inputs
│       ├── outputs.tf         # Module outputs
│       └── README.md          # Module documentation
├── environments/
│   ├── dev/                   # Development environment (eastus)
│   │   ├── main.tf            # Resource group, VNET, storage, VM
│   │   ├── providers.tf       # Provider and backend config
│   │   ├── variables.tf       # Environment variables
│   │   ├── locals.tf          # Naming convention and tags
│   │   ├── outputs.tf         # Environment outputs
│   │   └── terraform.tfvars   # Dev-specific values
│   └── prod/                  # Production environment (westus2)
│       ├── main.tf
│       ├── providers.tf
│       ├── variables.tf
│       ├── locals.tf
│       ├── outputs.tf
│       └── terraform.tfvars
├── .github/
│   └── workflows/
│       └── terraform.yml      # CI/CD pipeline (manual trigger)
├── .tflint.hcl                # TFLint configuration
├── .gitignore
└── README.md
```

## Architecture

### Reusable VNET Module

The `modules/vnet` module provisions:
- **Azure Virtual Network** with configurable address space and DNS
- **Subnets** with service endpoints and private endpoint policies
- **Network Security Groups** with custom rules per subnet
- **NSG-to-Subnet associations**

See [modules/vnet/README.md](modules/vnet/README.md) for full module documentation.

### Environment Configuration

Each environment deploys:
- **Resource Group** - logical container for all resources
- **Virtual Network** - using the reusable VNET module
- **Storage Account** - blob storage with network rules and versioning
- **Linux Virtual Machine** - Ubuntu 22.04 LTS with SSH key authentication
- **Public IP + NIC** - network connectivity for the VM

| Configuration          | Dev (`eastus`)     | Prod (`westus2`)    |
|------------------------|--------------------|---------------------|
| VNET CIDR              | 10.0.0.0/16        | 10.1.0.0/16         |
| VM Size                | Standard_B1s       | Standard_B2s        |
| OS Disk Type           | Standard_LRS       | Premium_LRS         |
| Storage Replication    | LRS                | GRS                 |
| Blob Retention         | 7 days             | 30 days             |
| NSG Rules              | HTTP, HTTPS, SSH   | HTTPS only          |

### Why Resource Groups Over Subscriptions?

Resource groups are used to separate environments because:
- **Simplicity**: no need to manage multiple Azure subscriptions
- **Cost tracking**: Azure Cost Management supports filtering by resource group
- **RBAC**: role-based access control can be scoped to a resource group
- **Suitable for small-to-medium setups**: subscription separation is better for large enterprises with strict isolation needs

## Naming Convention

All resources follow the pattern: `{resource-prefix}-{project}-{environment}-{region}`

Examples:
- `rg-opella-dev-eastus` (Resource Group)
- `vnet-opella-dev-eastus` (Virtual Network)
- `vm-opella-prod-westus2` (Virtual Machine)
- `stopelladeveastus` (Storage Account - no hyphens, Azure constraint)

## Tagging Strategy

All resources are tagged with:

| Tag         | Purpose                              |
|-------------|--------------------------------------|
| Environment | Identify the environment (dev/prod)  |
| Project     | Group resources by project           |
| Region      | Track resource location              |
| ManagedBy   | Indicate IaC management (terraform)  |

Tags are enforced via `local.common_tags` applied to every resource. Azure Policy can be used to enforce required tags at the subscription level.

## Prerequisites

- [Terraform](https://www.terraform.io/downloads) >= 1.5.0
- [Azure CLI](https://docs.microsoft.com/en-us/cli/azure/install-azure-cli) for authentication
- An Azure subscription (free tier works)
- SSH key pair for VM access

## Getting Started

1. **Authenticate with Azure:**
   ```bash
   az login
   ```

2. **Navigate to an environment:**
   ```bash
   cd environments/dev
   ```

3. **Initialize Terraform:**
   ```bash
   terraform init
   ```

4. **Review the plan:**
   ```bash
   terraform plan \
     -var="subscription_id=YOUR_SUBSCRIPTION_ID" \
     -var="vm_ssh_public_key=$(cat ~/.ssh/id_rsa.pub)"
   ```

5. **Apply:**
   ```bash
   terraform apply \
     -var="subscription_id=YOUR_SUBSCRIPTION_ID" \
     -var="vm_ssh_public_key=$(cat ~/.ssh/id_rsa.pub)"
   ```

## CI/CD Pipeline

The GitHub Actions pipeline (`.github/workflows/terraform.yml`) is triggered manually via `workflow_dispatch` with two inputs:

- **Environment**: `dev`, `prod`, or `all`
- **Action**: `plan` (review) or `apply` (deploy)

### Release Lifecycle

```
1. Developer creates a feature branch
2. Makes infrastructure changes
3. Opens a Pull Request
4. Reviewer reviews the code
5. After merge, manually trigger pipeline:
   - First: plan for dev → review output
   - Then: apply for dev → deploy to dev
   - After validation: apply for prod → deploy to prod
```

### Required GitHub Secrets

| Secret               | Description                     |
|----------------------|---------------------------------|
| ARM_CLIENT_ID        | Azure Service Principal app ID  |
| ARM_CLIENT_SECRET    | Azure Service Principal secret  |
| ARM_SUBSCRIPTION_ID  | Azure subscription ID           |
| ARM_TENANT_ID        | Azure AD tenant ID              |
| VM_SSH_PUBLIC_KEY    | SSH public key for VM auth      |

## Code Quality Tools

| Tool                                                        | Purpose                    |
|-------------------------------------------------------------|----------------------------|
| `terraform fmt`                                             | Consistent formatting      |
| `terraform validate`                                        | Configuration validation   |
| [TFLint](https://github.com/terraform-linters/tflint)      | Linting and best practices |
| [terraform-docs](https://terraform-docs.io/)                | Auto-generate module docs  |
| [checkov](https://www.checkov.io/)                          | Security scanning          |
| [pre-commit](https://pre-commit.com/)                      | Git hooks for automation   |

### Run Locally

```bash
# Format
terraform fmt -recursive

# Validate
cd environments/dev && terraform init && terraform validate

# Lint (requires tflint installed)
tflint --init
tflint --recursive
```
