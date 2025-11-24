# Databricks Platform Terraform Module

This module orchestrates the deployment of a complete Databricks platform on AWS, including workspace, Unity Catalog, multiple clusters, and multiple catalogs.

## 📋 Table of Contents

1. [Overview](#overview)
2. [What This Module Creates](#what-this-module-creates)
3. [Architecture](#architecture)
4. [Repository Structure](#-repository-structure)
5. [Prerequisites](#prerequisites)
6. [What You Need to Supply](#what-you-need-to-supply)
7. [Quick Start](#quick-start)
8. [End-to-End Deployment Steps](#end-to-end-deployment-steps)
9. [Module Usage](#module-usage)
10. [Inputs](#inputs)
11. [Outputs](#outputs)
12. [Examples](#examples)
13. [Troubleshooting](#troubleshooting)
14. [Module Dependencies](#module-dependencies)
15. [Resource Dependencies](#resource-dependencies)

---

## Overview

This module (`ub-tf-dbx-platform`) is the **platform orchestration layer** that:

- Creates a Databricks workspace on AWS
- Sets up Unity Catalog metastore
- Provisions multiple compute clusters
- Creates multiple Unity Catalog catalogs
- Manages all resources with consistent tagging and naming
- **Automatically stores and retrieves workspace credentials using AWS Secrets Manager**

It uses **Repo A** (`ub-tf-aws-databricks`) modules as building blocks and provides a simplified interface for deploying complete Databricks platforms.

### 🎯 **Key Features**

- ✅ **2-Pass Deployment** - Realistic workflow that matches Databricks requirements
- ✅ **Secrets Manager Integration** - Automatic credential storage/retrieval (no manual provider changes)
- ✅ **Direct Module Calls** - All Repo A modules called directly from `main.tf` (no wrapper modules)
- ✅ **Workspace URL Auto-Retrieval** - Automatically gets workspace URL from Repo A output
- ✅ **Multiple Resources** - Supports multiple clusters and catalogs via `for_each`

---

## What This Module Creates

### 1. **S3 Bucket**
- Shared S3 bucket for Databricks artifacts, logs, and Unity Catalog storage
- Versioning enabled
- Tagged with mandatory corporate tags

### 2. **Databricks Workspace**
- AWS-hosted Databricks workspace
- Connected to your existing VPC
- Configured with MWS objects (credentials, storage, network, private access)
- Outputs workspace URL and ID

### 3. **Unity Catalog Metastore**
- Unity Catalog metastore created in AWS
- Assigned to the workspace
- Configured with storage credentials and external locations
- Ready for catalog creation

### 4. **Multiple Compute Clusters**
- Creates one cluster per entry in the `clusters` map
- Each cluster with its own configuration:
  - Cluster name
  - Spark version
  - Node type (instance type)
  - Number of workers
- All clusters in the same workspace

### 5. **Multiple Unity Catalog Catalogs**
- Creates one catalog per entry in the `catalogs` map
- Each catalog with its own:
  - Storage root (S3 location for managed tables)
  - Grants (permissions)
- All catalogs in the same Unity Catalog metastore

---

## Architecture

```
┌─────────────────────────────────────────────────────────┐
│              Repo B: ub-tf-dbx-platform                 │
│              (This Module)                               │
│                                                          │
│  ┌──────────────────────────────────────────────────┐  │
│  │  main.tf (All Module Calls)                       │  │
│  │  ├─ S3 Bucket (external module)                  │  │
│  │  ├─ Databricks Workspace (external module)       │  │
│  │  ├─ Unity Catalog → Repo A unity-catalog          │  │
│  │  ├─ Multiple Clusters → Repo A cluster (for_each) │  │
│  │  └─ Multiple Catalogs → Repo A catalog (for_each)│  │
│  └──────────────────────────────────────────────────┘  │
│                                                          │
│  ┌──────────────────────────────────────────────────┐  │
│  │  Secrets Manager Integration                      │  │
│  │  ├─ data-secrets.tf (retrieve credentials)      │  │
│  │  └─ secrets-manager.tf (store credentials)       │  │
│  └──────────────────────────────────────────────────┘  │
│                                                          │
│  ┌──────────────────────────────────────────────────┐  │
│  │  Provider Configuration                          │  │
│  │  ├─ AWS Provider (workspace, Unity Catalog)      │  │
│  │  └─ Databricks Provider (clusters, catalogs)     │  │
│  │      └─ Auto-configured from Secrets Manager     │  │
│  └──────────────────────────────────────────────────┘  │
└───────────────────────────┬─────────────────────────────┘
                            │
                            ▼
┌─────────────────────────────────────────────────────────┐
│         Repo A: ub-tf-aws-databricks                     │
│         (Reusable Modules)                               │
│                                                          │
│  ┌──────────────────────────────────────────────────┐  │
│  │  Workspace Module                                 │  │
│  │  └─ Outputs: workspace_id, workspace_url          │  │
│  └──────────────────────────────────────────────────┘  │
│  ┌──────────────────────────────────────────────────┐  │
│  │  Unity Catalog Module                            │  │
│  │  └─ Outputs: metastore_id                        │  │
│  └──────────────────────────────────────────────────┘  │
│  ┌──────────────────────────────────────────────────┐  │
│  │  Cluster Module                                   │  │
│  │  └─ Outputs: cluster_id                          │  │
│  └──────────────────────────────────────────────────┘  │
│  ┌──────────────────────────────────────────────────┐  │
│  │  Catalog Module                                  │  │
│  │  └─ Outputs: catalog_name                        │  │
│  └──────────────────────────────────────────────────┘  │
└───────────────────────────┬─────────────────────────────┘
                            │
                            ▼
┌─────────────────────────────────────────────────────────┐
│    Databricks Official Terraform Modules                │
│    (terraform-databricks-examples)                      │
└─────────────────────────────────────────────────────────┘
```

### 🔄 **Credential Flow**

```
Pass-1: Workspace Creation
  ↓
Repo A Workspace Module
  ↓
Outputs: workspace_id, workspace_url
  ↓
Secrets Manager (auto-stored)
  ↓
Pass-2: Cluster/Catalog Creation
  ↓
Secrets Manager (auto-retrieved)
  ↓
Databricks Provider Configuration
  ↓
Cluster/Catalog Modules
```

---

## 📁 Repository Structure

```
ub-tf-dbx-platform/
├── main.tf                          # All module calls (S3, Workspace, UC, Clusters, Catalogs)
├── variables.tf                     # Input variable definitions
├── outputs.tf                      # Output values
├── provider.tf                     # AWS and Databricks provider configuration
├── versions.tf                     # Terraform and provider version requirements
├── locals.tf                       # Local values and naming conventions
├── data-secrets.tf                 # Secrets Manager data sources (retrieve credentials)
├── secrets-manager.tf              # Secrets Manager resources (store credentials)
├── README.md                       # This file
├── README_SECRETS_MANAGER.md       # Detailed Secrets Manager documentation
└── examples/                       # Complete working example
    ├── main.tf
    ├── variables.tf
    ├── terraform.tfvars.example
    ├── README.md
    └── DEPLOYMENT_CHECKLIST.md
```

### Key Files Explained

- **`main.tf`** - Contains all module calls directly referencing Repo A modules (no wrapper modules)
- **`data-secrets.tf`** - Retrieves workspace URL and PAT from Secrets Manager with fallback chain
- **`secrets-manager.tf`** - Automatically stores workspace URL and PAT in Secrets Manager (no script needed!)
- **`provider.tf`** - Configures providers using locals (auto-retrieves from Secrets Manager)

---

## Prerequisites

### 1. **Terraform & AWS**
- Terraform >= 1.5.0
- AWS CLI configured
- AWS credentials with appropriate permissions

### 2. **Databricks Account Console Access**
- Access to Databricks Account Console (MWS/Accounts API)
- Permissions to create workspaces and Unity Catalog metastores

### 3. **Pre-Created MWS Objects**
You must have these objects created in Databricks Account Console:
- **Credentials ID** - Cross-account IAM role
- **Storage Configuration ID** - S3 bucket configuration
- **Network ID** - VPC attachment configuration
- **Private Access Settings ID** - Private connectivity settings

**How to get these:**
1. Log into Databricks Account Console
2. Navigate to **Settings** → **Account Settings**
3. Find the IDs for each object type

### 4. **AWS Resources**
- Existing VPC with private subnets (at least 2 in different AZs)
- Security groups configured for Databricks
- S3 buckets for Unity Catalog (if using external locations)

### 5. **AWS Secrets Manager Permissions**
- Permissions to create/read/update secrets in AWS Secrets Manager
- Required IAM permissions:
  - `secretsmanager:CreateSecret`
  - `secretsmanager:GetSecretValue`
  - `secretsmanager:UpdateSecret`
  - `secretsmanager:DescribeSecret`

---

## What You Need to Supply

### 🔑 Required Inputs

#### 1. **Core Identity**
```hcl
product_name = "damage-prevention"  # Your product/project name
service      = "databricks"          # Service name
environment  = "intg"                # Environment: intg, stag, prod, demo
region       = "us-east-2"          # AWS region
```

#### 2. **Databricks Account / MWS IDs**
```hcl
databricks_account_id          = "1234567890123456"  # From Account Console
mws_credentials_id             = "cred-123"          # From Account Console
mws_storage_config_id          = "storage-123"       # From Account Console
mws_network_id                 = "network-123"       # From Account Console
mws_private_access_settings_id = "pas-123"           # From Account Console
```

#### 3. **Workspace Authentication**

**Recommended: Use Secrets Manager (Default - 2-Pass Deployment)**

```hcl
# In terraform.tfvars - for Pass-1, leave empty
workspace_pat = ""  # Leave empty for Pass-1, will be stored after workspace creation
use_secrets_manager = true  # Default: true
```

**How It Works:**
1. **Pass-1:** Workspace URL and workspace_id automatically stored in Secrets Manager (no PAT needed)
2. **Manual Step:** Create PAT in workspace UI
3. **Pass-2:** Add `workspace_pat` to `terraform.tfvars` and run `terraform apply` - Terraform automatically stores PAT in Secrets Manager and retrieves all credentials

**Alternative: Provide Manually (Single-Pass)**

If you already have a PAT, you can provide it directly:

```hcl
workspace_pat = "dapi..."  # Personal Access Token (must exist before terraform apply)
use_secrets_manager = false
```

**Required Permissions for PAT:**
- Workspace admin or cluster creation permissions
- Unity Catalog admin permissions (for catalog creation)

**See `README_SECRETS_MANAGER.md` for complete Secrets Manager setup instructions.**

#### 4. **Unity Catalog Required Variables**
```hcl
aws_account_id        = "123456789012"      # Your AWS account ID
unity_metastore_owner = "admin@example.com" # Email or service principal
prefix                = "dp"                # Resource prefix
```

#### 5. **VPC Configuration**
```hcl
vpc_id = "vpc-0123456789abcdef0"  # Your existing VPC ID

private_subnet_ids = [
  "subnet-aaa111",  # At least 2 subnets in different AZs
  "subnet-bbb222",
]

security_group_ids = [
  "sg-0123abcd",  # Security group with Databricks rules
]
```

#### 6. **Mandatory Tags**
```hcl
tags = {
  owner      = "data-platform-team"  # Team/owner name
  env        = "intg"                 # Must be: intg, stag, prod, demo
  product    = "damage-prevention"    # Product name
  service    = "databricks"           # Service name
  repo       = "ub-tf-dbx-platform"  # Repository name
  created_by = "terraform"            # Creator
  customer   = "urbint"               # Customer name
  region     = "us-east-2"            # AWS region
}
```

**Important:** All 8 tags are **mandatory** and validated by the module.

#### 7. **Workspace Configuration**
```hcl
workspace = {
  # Workspace Settings
  workspace_name = "dp-intg-ws"      # Workspace name
  pricing_tier   = "STANDARD"        # STANDARD, PREMIUM, or ENTERPRISE

  # Unity Catalog
  uc_metastore_name   = "dp-intg-metastore"  # Metastore name
  uc_metastore_region = "us-east-2"          # Region for metastore
  uc_external_prefix  = "s3://dp-intg-uc/"   # S3 prefix for external locations
  uc_storage_role_arn = "arn:aws:iam::123456789012:role/uc-role"  # IAM role ARN

  # Multiple Clusters
  clusters = {
    analytics = {
      cluster_name  = "dp-intg-analytics"
      spark_version = "13.3.x-scala2.12"  # Databricks runtime version
      node_type_id  = "i3.xlarge"         # Instance type
      num_workers   = 2                    # Number of worker nodes
    }
    etl = {
      cluster_name  = "dp-intg-etl"
      spark_version = "13.3.x-scala2.12"
      node_type_id  = "i3.2xlarge"
      num_workers   = 4
    }
  }

  # Multiple Catalogs
  catalogs = {
    production = {
      storage_root = "s3://dp-intg-uc/production/"  # S3 location for managed tables
      grants = [
        {
          principal  = "data-engineers"              # Group or user
          privileges = ["USE_CATALOG", "CREATE_SCHEMA"]
        }
      ]
    }
    analytics = {
      storage_root = "s3://dp-intg-uc/analytics/"
      grants = []  # No grants
    }
  }
}
```

---

## Quick Start

### Using from Repo C (Environment Layer)

```hcl
module "dbx_platform" {
  source = "git::https://github.com/<org>/ub-tf-dbx-platform.git?ref=<tag>"

  # Core identity
  product_name = "damage-prevention"
  service      = "databricks"
  environment  = "intg"
  region       = "us-east-2"

  # Databricks Account / MWS
  databricks_account_id          = var.databricks_account_id
  mws_credentials_id             = var.mws_credentials_id
  mws_storage_config_id          = var.mws_storage_config_id
  mws_network_id                 = var.mws_network_id
  mws_private_access_settings_id = var.mws_private_access_settings_id

  # Workspace Authentication
  workspace_pat = var.workspace_pat

  # Unity Catalog
  aws_account_id        = var.aws_account_id
  unity_metastore_owner = var.unity_metastore_owner
  prefix                = var.prefix

  # VPC
  vpc_id             = var.vpc_id
  private_subnet_ids = var.private_subnet_ids
  security_group_ids = var.security_group_ids

  # Configuration
  tags      = var.tags
  workspace = var.workspace
}
```

### Using from Examples Folder

See the [`examples/`](./examples/) directory for a complete working example.

---

## 📁 Repository Structure

```
ub-tf-dbx-platform/
├── main.tf                          # All module calls (S3, Workspace, UC, Clusters, Catalogs)
├── variables.tf                     # Input variable definitions
├── outputs.tf                      # Output values
├── provider.tf                     # AWS and Databricks provider configuration
├── versions.tf                     # Terraform and provider version requirements
├── locals.tf                       # Local values and naming conventions
├── data-secrets.tf                 # Secrets Manager data sources (retrieve credentials)
├── secrets-manager.tf              # Secrets Manager resources (store credentials)
├── README.md                       # This file
├── README_SECRETS_MANAGER.md       # Detailed Secrets Manager documentation
└── examples/                       # Complete working example
    ├── main.tf
    ├── variables.tf
    ├── terraform.tfvars.example
    ├── README.md
    └── DEPLOYMENT_CHECKLIST.md
```

### Key Files Explained

- **`main.tf`** - Contains all module calls directly referencing Repo A modules (no wrapper modules)
- **`data-secrets.tf`** - Retrieves workspace URL and PAT from Secrets Manager with fallback chain
- **`secrets-manager.tf`** - Automatically stores workspace URL and PAT in Secrets Manager (no script needed!)
- **`provider.tf`** - Configures providers using locals (auto-retrieves from Secrets Manager)

---

## End-to-End Deployment Steps

This module uses a **2-pass deployment strategy** with AWS Secrets Manager integration for seamless credential management. No manual provider configuration changes are needed between passes.

---

### 📋 **Prerequisites**

1. **Create MWS Objects in Databricks Account Console:**
   - Credentials (cross-account IAM role)
   - Storage Configuration (S3 bucket)
   - Network (VPC attachment)
   - Private Access Settings

2. **Prepare AWS Resources:**
   - Identify VPC ID
   - Identify private subnet IDs (at least 2 in different AZs)
   - Identify security group IDs
   - Create S3 buckets for Unity Catalog (if needed)

3. **AWS Secrets Manager Permissions:**
   - Ensure your AWS credentials have permissions to create/read secrets
   - Required permissions: `secretsmanager:CreateSecret`, `secretsmanager:GetSecretValue`, `secretsmanager:UpdateSecret`

---

### 🔧 **Step 1: Configure Module Source**

If using Git source, ensure Repo A modules are accessible:

1. Update module sources in `main.tf`:
   - Unity Catalog module (line ~46)
   - Catalog module (line ~77)
   - Cluster module (line ~107)

   Replace `<org>` and `<tag>` with actual values.

---

### 📝 **Step 2: Create Terraform Configuration**

Create a `main.tf` file:

```hcl
module "dbx_platform" {
  source = "git::https://github.com/<org>/ub-tf-dbx-platform.git?ref=<tag>"
  
  # ... all required variables (see above)
}
```

---

### 📄 **Step 3: Create Variables File**

Create `terraform.tfvars` with all required values:

```hcl
# Copy from examples/terraform.tfvars.example
# Fill in all values marked with # CHANGE

# For Pass-1, you can leave workspace_pat empty or omit it
# Secrets Manager will be used automatically (default: use_secrets_manager = true)
workspace_pat = ""  # Leave empty for Pass-1
use_secrets_manager = true  # Default: true
```

---

### 🚀 **PASS-1: Create Workspace + Unity Catalog**

**What Gets Created:**
- ✅ S3 Bucket
- ✅ Databricks Workspace
- ✅ Unity Catalog Metastore

**What You Need:**
- All MWS IDs
- VPC configuration
- Unity Catalog configuration
- **NO PAT required!**

#### Step 4: Initialize Terraform

```bash
terraform init
```

This will:
- Download AWS and Databricks providers
- Download the root module
- Download Repo A modules (directly referenced in main.tf)

#### Step 5: Validate Configuration

```bash
terraform validate
```

Checks for syntax errors and validates variable types.

#### Step 6: Review Plan (Pass-1)

```bash
terraform plan
```

Review the plan. You should see:
- ✅ S3 bucket creation
- ✅ Databricks workspace creation
- ✅ Unity Catalog metastore creation
- ⏭️ Clusters and catalogs will be skipped (PAT not available yet)

#### Step 7: Apply Pass-1

```bash
terraform apply
```

Type `yes` when prompted.

**Expected Duration:**
- Workspace: ~15-20 minutes
- Unity Catalog: ~5-10 minutes

**Total: ~20-30 minutes**

#### Step 8: Capture Workspace Information

After Pass-1 completes:

```bash
terraform output
```

You should see:
- `workspace_id` - Workspace ID
- `workspace_url` - Workspace URL (save this!)
- `metastore_id` - Unity Catalog metastore ID

**What Happens Automatically:**
- ✅ Workspace URL is automatically stored in AWS Secrets Manager
- ✅ Workspace ID is available for Unity Catalog

---

### 🔑 **Step 9: Create and Store PAT (Manual Step)**

**This is the only manual step between passes!**

1. **Log into Databricks Workspace:**
   - Use the `workspace_url` from Pass-1 output
   - Log in with your Databricks account

2. **Create Personal Access Token:**
   - Go to **User Settings** → **Access Tokens**
   - Click **Generate New Token**
   - Name: `terraform-<environment>` (e.g., `terraform-intg`)
   - Lifetime: Set appropriate expiration (e.g., 90 days)
   - Permissions: Ensure it has:
     - ✅ Cluster creation permissions
     - ✅ Unity Catalog admin permissions
   - Click **Generate**
   - **Copy the token immediately** (you won't see it again!)

3. **Store PAT in Terraform (Automatic - No Script Needed!):**

   **✅ NEW: Just add PAT to `terraform.tfvars` - Terraform handles the rest!**
   
   Add the PAT to your `terraform.tfvars` file:
   
   ```hcl
   # In terraform.tfvars (for Pass-2)
   workspace_pat = "dapi1234567890abcdef..."  # Your PAT from Step 2
   ```
   
   **That's it!** When you run `terraform apply` for Pass-2, Terraform will:
   - ✅ Automatically store the PAT in AWS Secrets Manager
   - ✅ Retrieve workspace URL from Secrets Manager
   - ✅ Use both for cluster and catalog creation
   
   **No manual script or AWS CLI commands needed!**

---

### 🚀 **PASS-2: Create Clusters + Catalogs**

**What Gets Created:**
- ✅ Multiple Clusters (one per entry in `clusters` map)
- ✅ Multiple Catalogs (one per entry in `catalogs` map)

**What Happens Automatically:**
- ✅ Workspace URL retrieved from Secrets Manager
- ✅ PAT retrieved from Secrets Manager
- ✅ **No manual provider.tf changes needed!**

#### Step 10: Review Plan (Pass-2)

```bash
terraform plan
```

Review the plan. You should see:
- ✅ Multiple cluster creations (one per entry in `clusters` map)
- ✅ Multiple catalog creations (one per entry in `catalogs` map)
- ⏭️ Workspace and Unity Catalog already exist (no changes)

#### Step 11: Apply Pass-2

```bash
terraform apply
```

Type `yes` when prompted.

**Expected Duration:**
- Clusters: ~5-10 minutes each
- Catalogs: ~2-5 minutes each

**Total: ~10-30 minutes** depending on number of clusters/catalogs

---

### ✅ **Step 12: Verify Deployment**

After successful deployment:

```bash
terraform output
```

You should see:
- `s3_bucket_name` - S3 bucket for artifacts
- `workspace_id` - Workspace ID
- `workspace_url` - Workspace URL
- `metastore_id` - Unity Catalog metastore ID
- `cluster_ids` - Map of cluster IDs
- `catalog_names` - Map of catalog names

**Verify in Databricks:**
1. Log into workspace URL
2. Go to **Compute** → Verify clusters are created and running
3. Go to **Data** → **Catalogs** → Verify catalogs are created
4. Go to **Settings** → **Unity Catalog** → Verify metastore is assigned

---

### 🔄 **Step 13: Post-Deployment**

1. **Create Schemas** (if needed):
   - Use Databricks UI or SQL
   - Or use separate Terraform resources

2. **Configure Access:**
   - Add users/groups to workspace
   - Configure workspace-level permissions
   - Set up catalog-level permissions

3. **Deploy Workloads:**
   - Deploy notebooks, jobs, and pipelines
   - Use the created clusters and catalogs

---

## 🎯 **Deployment Summary**

| Pass | Resources Created | PAT Required? | Duration |
|------|------------------|---------------|----------|
| **Pass-1** | S3, Workspace, Unity Catalog | ❌ No | ~20-30 min |
| **Manual** | Create PAT, Store in Secrets Manager | ✅ Yes | ~5 min |
| **Pass-2** | Clusters, Catalogs | ✅ Auto-retrieved | ~10-30 min |
| **Total** | All resources | - | **~35-65 min** |

---

## 🔄 **Alternative: Single-Pass Deployment**

If you already have a PAT stored in Secrets Manager (from a previous deployment), you can deploy everything in one pass:

1. Ensure PAT exists in Secrets Manager
2. Run `terraform apply` once
3. All resources created in single pass

**Use Case:** Re-deploying or updating existing infrastructure.

---

## Module Usage

### Basic Example

```hcl
module "dbx_platform" {
  source = "git::https://github.com/<org>/ub-tf-dbx-platform.git?ref=<tag>"

  product_name = "my-product"
  service      = "databricks"
  environment  = "intg"
  region       = "us-east-2"

  databricks_account_id          = "1234567890123456"
  mws_credentials_id             = "cred-123"
  mws_storage_config_id          = "storage-123"
  mws_network_id                 = "network-123"
  mws_private_access_settings_id = "pas-123"

  workspace_pat = "dapi..."

  aws_account_id        = "123456789012"
  unity_metastore_owner = "admin@example.com"
  prefix                = "mp"

  vpc_id             = "vpc-12345"
  private_subnet_ids = ["subnet-1", "subnet-2"]
  security_group_ids = ["sg-12345"]

  tags = {
    owner      = "data-team"
    env        = "intg"
    product    = "my-product"
    service    = "databricks"
    repo       = "ub-tf-dbx-platform"
    created_by = "terraform"
    customer   = "internal"
    region     = "us-east-2"
  }

  workspace = {
    workspace_name = "my-product-intg-ws"
    pricing_tier   = "PREMIUM"

    uc_metastore_name   = "my-product-intg-metastore"
    uc_metastore_region = "us-east-2"
    uc_external_prefix  = "s3://my-product-intg-uc/"
    uc_storage_role_arn = "arn:aws:iam::123456789012:role/uc-role"

    clusters = {
      analytics = {
        cluster_name  = "my-product-intg-analytics"
        spark_version = "13.3.x-scala2.12"
        node_type_id  = "i3.xlarge"
        num_workers   = 2
      }
    }

    catalogs = {
      production = {
        storage_root = "s3://my-product-intg-uc/production/"
        grants       = []
      }
    }
  }
}
```

---

## Inputs

| Name | Description | Type | Required | Default |
|------|-------------|------|----------|---------|
| `product_name` | Product/project name | `string` | yes | - |
| `service` | Service name | `string` | yes | - |
| `environment` | Environment (intg, stag, prod, demo) | `string` | yes | - |
| `region` | AWS region | `string` | yes | - |
| `databricks_account_id` | Databricks Account ID | `string` | yes | - |
| `mws_credentials_id` | MWS credentials ID | `string` | yes | - |
| `mws_storage_config_id` | MWS storage configuration ID | `string` | yes | - |
| `mws_network_id` | MWS network ID | `string` | yes | - |
| `mws_private_access_settings_id` | MWS private access settings ID | `string` | yes | - |
| `workspace_pat` | Databricks Personal Access Token | `string` | yes | - |
| `aws_account_id` | AWS account ID | `string` | yes | - |
| `unity_metastore_owner` | Unity Catalog metastore owner | `string` | yes | - |
| `prefix` | Resource prefix | `string` | yes | - |
| `vpc_id` | Existing VPC ID | `string` | yes | - |
| `private_subnet_ids` | Private subnet IDs | `list(string)` | yes | - |
| `security_group_ids` | Security group IDs | `list(string)` | yes | - |
| `tags` | Mandatory corporate tags | `map(string)` | yes | - |
| `workspace` | Workspace configuration object | `object` | yes | - |

See [`variables.tf`](./variables.tf) for detailed variable descriptions.

---

## Outputs

| Name | Description |
|------|-------------|
| `s3_bucket_name` | Shared S3 bucket for artifacts |
| `workspace_id` | Databricks workspace ID |
| `workspace_url` | Databricks workspace URL |
| `metastore_id` | Unity Catalog metastore ID |
| `cluster_ids` | Map of cluster IDs keyed by cluster key |

See [`outputs.tf`](./outputs.tf) for detailed output descriptions.

---

## Examples

### Complete Working Example

See the [`examples/`](./examples/) directory for a complete, working example with:
- Full configuration
- All required variables
- Step-by-step deployment guide
- Troubleshooting tips

### Multiple Environments

This module is typically used from **Repo C** (`ub-tf-dbx-envs`) for different environments:

```
ub-tf-dbx-envs/
├── terraform/
│   ├── intg/
│   │   ├── main.tf          # Calls Repo B
│   │   └── terraform.tfvars # Environment-specific values
│   ├── stag/
│   │   └── ...
│   └── prod/
│       └── ...
```

---

## Troubleshooting

### Common Issues

#### Error: "Missing required variable"
**Solution:** Ensure all required variables are provided in your configuration.

#### Error: "Invalid MWS ID"
**Solution:** Verify MWS IDs in Databricks Account Console. Format should be like `cred-123`, `storage-123`, etc.

#### Error: "Workspace PAT invalid"
**Solution:**
- Regenerate PAT in Databricks
- Ensure PAT has required permissions
- Check PAT hasn't expired
- If using Secrets Manager, verify PAT is stored correctly:
  ```bash
  aws secretsmanager get-secret-value \
    --secret-id "<product>-<env>-<region>-databricks-workspace" \
    --region <region> \
    --query SecretString --output text | jq .
  ```

#### Error: "Secret not found in Secrets Manager"
**Solution:**
- This is normal for Pass-1 (secret doesn't exist yet)
- After Pass-1, the secret is automatically created
- For Pass-2, ensure PAT is stored in Secrets Manager using the provided script

#### Error: "VPC subnet validation failed"
**Solution:**
- Ensure subnets are private (not public)
- Ensure subnets are in at least 2 different availability zones
- Verify security groups allow outbound HTTPS (443)

#### Error: "Tag validation failed"
**Solution:** Ensure all mandatory tags are present:
- `owner`, `env`, `product`, `service`, `repo`, `created_by`, `customer`, `region`
- `env` must be one of: `intg`, `stag`, `prod`, `demo`

#### Error: "Cluster creation failed"
**Solution:**
- Verify `workspace_pat` has cluster creation permissions
- Check node type is available in your region
- Verify spark version is valid

#### Error: "Catalog creation failed"
**Solution:**
- Verify Unity Catalog metastore is created first
- Check `storage_root` S3 path exists and is accessible
- Verify `workspace_pat` has Unity Catalog admin permissions

### Workspace Creation Takes Too Long
**Normal:** Workspace creation can take 15-20 minutes. This is expected.

### Resources Not Appearing in Databricks UI
**Solution:**
- Wait a few minutes for UI to refresh
- Log out and log back into workspace
- Check workspace URL is correct

---

## Module Dependencies

This module depends on:

1. **Repo A** (`ub-tf-aws-databricks`) - Reusable Databricks modules
   - `unity-catalog` module - Creates Unity Catalog metastore
   - `catalog` module - Creates Unity Catalog catalogs
   - `cluster` module - Creates Databricks clusters
   - `workspace` module - Creates Databricks workspace (via external module)

2. **External Modules:**
   - `ub-tf-aws-s3` - S3 bucket creation
   - `terraform-databricks-examples` - Official Databricks workspace module

3. **Terraform Providers:**
   - **AWS Provider** - For workspace and Unity Catalog creation (MWS API)
   - **Databricks Provider** - For cluster and catalog operations (Workspace API)

4. **AWS Services:**
   - **Secrets Manager** - For automatic credential storage/retrieval

---

## Resource Dependencies

```
┌─────────────────────────────────────────────────────────┐
│                    PASS-1                               │
│                                                          │
│  S3 Bucket (independent)                                │
│      ↓                                                   │
│  Workspace (independent)                                │
│      ↓                                                   │
│  Unity Catalog Metastore (needs workspace_id)          │
│      ↓                                                   │
│  Secrets Manager Secret (stores workspace_url)          │
└─────────────────────────────────────────────────────────┘
                        │
                        │ Manual Step: Create PAT, Store in Secrets Manager
                        ▼
┌─────────────────────────────────────────────────────────┐
│                    PASS-2                               │
│                                                          │
│  Clusters (need workspace_url + workspace_pat)         │
│      ↓                                                   │
│  Catalogs (need workspace + Unity Catalog)             │
│                                                          │
│  Note: workspace_url and workspace_pat automatically   │
│        retrieved from Secrets Manager                   │
└─────────────────────────────────────────────────────────┘
```

---

## Cleanup

To destroy all resources:

```bash
terraform destroy
```

**Warning:** This will delete:
- All clusters
- All catalogs
- Unity Catalog metastore
- Databricks workspace
- S3 bucket

**Note:** MWS objects (credentials, storage config, etc.) are NOT deleted as they're managed separately.

---

## Support

For issues or questions:
1. Check this README
2. Review the [examples README](./examples/README.md)
3. Check Terraform error messages
4. Review Databricks documentation
5. Contact your platform team

---

## License

[Your License Here]

---

**Happy Deploying! 🚀**
