# End-to-End Infrastructure Deployment Guide

This guide walks you through deploying a complete Databricks platform infrastructure using the `ub-tf-dbx-platform` module.

**✨ Key Features:**
- **2-Pass Deployment** - Realistic workflow that matches Databricks requirements
- **AWS Secrets Manager Integration** - Automatic credential storage/retrieval (no manual provider changes)
- **Direct Module Calls** - All Repo A modules called directly from `main.tf` (no wrapper modules)
- **Workspace URL Auto-Retrieval** - Automatically gets workspace URL from Repo A output

This module uses a **2-pass deployment strategy** with AWS Secrets Manager integration for seamless credential management. No manual provider configuration changes are needed between passes.

## 📋 Table of Contents

1. [Prerequisites](#prerequisites)
2. [What You Need to Provide](#what-you-need-to-provide)
3. [Step-by-Step Deployment](#step-by-step-deployment)
4. [Configuration Details](#configuration-details)
5. [Troubleshooting](#troubleshooting)
6. [Secrets Manager Integration](#secrets-manager-integration)

---

## Prerequisites

### 1. **Terraform Setup**
- Terraform >= 1.5.0
- AWS CLI configured with appropriate credentials
- Access to your AWS account

### 2. **Databricks Account Console Access**
- Access to Databricks Account Console (MWS/Accounts API)
- Permissions to create workspaces, Unity Catalog metastores, clusters, and catalogs

### 3. **Pre-Created MWS Objects**
You must have these objects created in your Databricks Account Console:
- **Credentials ID** - Cross-account IAM role for Databricks
- **Storage Configuration ID** - S3 bucket configuration for workspace root
- **Network ID** - VPC attachment configuration
- **Private Access Settings ID** - Private connectivity settings

### 4. **AWS Resources**
- Existing VPC with private subnets
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

## What You Need to Provide

### 🔑 Required Variables

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

**How to get these:**
1. Log into Databricks Account Console
2. Navigate to **Settings** → **Account Settings**
3. Find the IDs for each object type

#### 3. **Workspace Authentication**

**Recommended: Use Secrets Manager (Default - 2-Pass Deployment)**

```hcl
# In terraform.tfvars - for Pass-1, leave empty
workspace_pat = ""  # Leave empty for Pass-1, will be stored after workspace creation
use_secrets_manager = true  # Default: true
```

**How It Works:**
1. **Pass-1:** Workspace URL automatically stored in Secrets Manager (no PAT needed)
2. **Manual Step:** Create PAT in workspace, store in Secrets Manager using provided script
3. **Pass-2:** Both workspace URL and PAT automatically retrieved from Secrets Manager

**Alternative: Provide Manually (Single-Pass)**

If you already have a PAT, you can provide it directly:

```hcl
workspace_pat = "dapi..."  # Personal Access Token (must exist before terraform apply)
use_secrets_manager = false
```

**How to create a PAT:**
1. Log into your Databricks workspace (after Pass-1)
2. Go to **User Settings** → **Access Tokens**
3. Click **Generate New Token**
4. Give it a name and expiration
5. **Required Permissions:**
   - Workspace admin or cluster creation permissions
   - Unity Catalog admin permissions (for catalog creation)

**Secrets Manager Setup:**
- After Pass-1, workspace URL is automatically stored in Secrets Manager
- ✅ NEW: Just add `workspace_pat` to `terraform.tfvars` for Pass-2 - Terraform stores it automatically
- No script needed! See `../README_SECRETS_MANAGER.md` for complete setup instructions
- Secret name format: `{product_name}-{environment}-{region}-databricks-workspace`

#### 4. **Unity Catalog Required Variables**
```hcl
aws_account_id        = "123456789012"      # Your AWS account ID
unity_metastore_owner = "admin@example.com" # Email or service principal
prefix                = "dp"                # Resource prefix
```

**Details:**
- `aws_account_id`: Your 12-digit AWS account ID
- `unity_metastore_owner`: Email address or service principal that will own the metastore
- `prefix`: Short prefix for resource naming (e.g., "dp" for damage-prevention)

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

**Requirements:**
- VPC must have private subnets in at least 2 availability zones
- Security groups must allow:
  - Outbound HTTPS (443) to Databricks
  - Outbound traffic for cluster communication

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

**Important:** All these tags are **mandatory** and validated by the module.

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

**Cluster Configuration:**
- `cluster_name`: Unique name for the cluster
- `spark_version`: Databricks runtime version (e.g., "13.3.x-scala2.12")
- `node_type_id`: AWS instance type (e.g., "i3.xlarge", "m5.2xlarge")
- `num_workers`: Number of worker nodes (0 for single-node, 1+ for multi-node)

**Catalog Configuration:**
- `storage_root`: S3 path where managed tables will be stored (must end with `/`)
- `grants`: Optional list of permissions to grant on the catalog

---

## Step-by-Step Deployment

### Step 1: Clone and Navigate to Examples

```bash
cd ub-tf-dbx-platform/examples
```

### Step 2: Copy Example Variables File

```bash
cp terraform.tfvars.example terraform.tfvars
```

### Step 3: Update `terraform.tfvars`

Edit `terraform.tfvars` and fill in all the required values (see [What You Need to Provide](#what-you-need-to-provide) above).

**Critical values to update:**
- ✅ All MWS IDs from Account Console
- ✅ `workspace_pat` - Your Databricks PAT (optional if using Secrets Manager)
- ✅ `use_secrets_manager` - Set to `true` to use Secrets Manager (default)
- ✅ `aws_account_id` - Your AWS account ID
- ✅ `unity_metastore_owner` - Email address
- ✅ `prefix` - Resource prefix
- ✅ VPC, subnet, and security group IDs
- ✅ All tags
- ✅ Workspace configuration (clusters, catalogs)

**Note:** If using Secrets Manager (default), you can leave `workspace_pat` empty. After workspace creation, store the PAT in Secrets Manager using the provided script.

### Step 4: Update Module Source URLs (If Using Git)

If you're using Git sources for Repo A modules, update these files:
- `../main.tf` - Unity Catalog module (line ~46)
- `../main.tf` - Catalog module (line ~77)
- `../main.tf` - Cluster module (line ~107)

Replace `<org>` and `<tag>` with your actual values:
```hcl
source = "git::https://github.com/YOUR_ORG/ub-tf-aws-databricks.git//cluster?ref=v1.0.0"
```

### Step 5: Provider Configuration

The `provider.tf` in the examples folder only needs AWS provider configuration:

```hcl
provider "aws" {
  region = var.region
  # Credentials from AWS CLI or environment variables
}
```

**Note:** 
- The Databricks provider is configured automatically in the root module
- It uses Secrets Manager to retrieve workspace URL and PAT
- **No manual provider configuration changes needed between passes!**

### Step 6: Initialize Terraform

```bash
terraform init
```

This will:
- Download required providers (AWS, Databricks)
- Download the root module (parent directory)
- Download Repo A modules (directly referenced in main.tf)

### Step 7: Validate Configuration

```bash
terraform validate
```

This checks for syntax errors and validates variable types.

### Step 8: Plan Deployment

```bash
terraform plan
```

Review the plan carefully. You should see:
- ✅ S3 bucket creation
- ✅ Databricks workspace creation
- ✅ Unity Catalog metastore creation
- ✅ Multiple cluster creations (one per entry in `clusters` map)
- ✅ Multiple catalog creations (one per entry in `catalogs` map)

### Step 9: Apply Configuration

```bash
terraform apply
```

Type `yes` when prompted. This will create all resources.

**Expected Duration:**
- Workspace creation: ~15-20 minutes
- Unity Catalog: ~5-10 minutes
- Clusters: ~5-10 minutes each
- Catalogs: ~2-5 minutes each

**Total: ~30-60 minutes** depending on number of clusters/catalogs

### Step 10: Verify Deployment

After successful deployment, you'll see outputs:

```bash
terraform output
```

You should see:
- `s3_bucket_name` - S3 bucket for artifacts
- `workspace_url` - Your Databricks workspace URL
- `workspace_id` - Workspace ID
- `metastore_id` - Unity Catalog metastore ID
- `cluster_ids` - Map of cluster IDs

**Verify in Databricks:**
1. Log into the workspace URL
2. Go to **Compute** → Verify clusters are created
3. Go to **Data** → **Catalogs** → Verify catalogs are created
4. Go to **Settings** → **Unity Catalog** → Verify metastore is assigned

---

## Configuration Details

### Cluster Configuration Options

**Spark Versions:**
- Latest LTS: `13.3.x-scala2.12`
- Other options: Check Databricks documentation for available runtimes

**Node Types:**
- Compute optimized: `i3.xlarge`, `i3.2xlarge`
- General purpose: `m5.xlarge`, `m5.2xlarge`
- Memory optimized: `r5.xlarge`, `r5.2xlarge`

**Worker Count:**
- `0` = Single-node cluster (driver only)
- `1+` = Multi-node cluster (driver + workers)

### Catalog Grants

**Common Privileges:**
- `USE_CATALOG` - Can use the catalog
- `CREATE_SCHEMA` - Can create schemas
- `ALL_PRIVILEGES` - Full access

**Principals:**
- Groups: `"data-engineers"`
- Users: `"user@example.com"`
- Service principals: `"1234567890@service.databricks.com"`

### Pricing Tiers

- `STANDARD` - Basic features
- `PREMIUM` - Advanced features, Unity Catalog
- `ENTERPRISE` - All features, enhanced support

---

## Troubleshooting

### Error: "Missing required variable"

**Solution:** Ensure all required variables in `terraform.tfvars` are filled in.

### Error: "Invalid MWS ID"

**Solution:** Verify MWS IDs in Databricks Account Console. They should be in format like `cred-123`, `storage-123`, etc.

### Error: "Workspace PAT invalid"

**Possible causes:**
- PAT has expired
- PAT doesn't have required permissions
- PAT was revoked
- PAT not found in Secrets Manager (if using Secrets Manager)

**Solution:**
- Regenerate PAT in Databricks
- If using Secrets Manager, update PAT in terraform.tfvars:
  ```hcl
  # In terraform.tfvars
  workspace_pat = "NEW_PAT"
  ```
  ```bash
  terraform apply  # Terraform automatically updates Secrets Manager
  ```
- Ensure PAT has required permissions
- Check PAT hasn't expired
- Verify PAT is stored correctly in Secrets Manager:
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

### Error: "VPC subnet validation failed"

**Solution:**
- Ensure subnets are in private subnets (not public)
- Ensure subnets are in at least 2 different availability zones
- Verify security groups allow outbound HTTPS (443)

### Error: "Tag validation failed"

**Solution:** Ensure all mandatory tags are present:
- `owner`, `env`, `product`, `service`, `repo`, `created_by`, `customer`, `region`
- `env` must be one of: `intg`, `stag`, `prod`, `demo`

### Error: "Cluster creation failed"

**Solution:**
- Verify `workspace_pat` has cluster creation permissions
- If using Secrets Manager, verify secret exists and contains valid PAT
- Check node type is available in your region
- Verify spark version is valid

### Error: "Catalog creation failed"

**Solution:**
- Verify Unity Catalog metastore is created first
- Check `storage_root` S3 path exists and is accessible
- Verify `workspace_pat` has Unity Catalog admin permissions
- If using Secrets Manager, verify secret exists and contains valid PAT

### Workspace Creation Takes Too Long

**Normal:** Workspace creation can take 15-20 minutes. This is expected.

### Resources Not Appearing in Databricks UI

**Solution:**
- Wait a few minutes for UI to refresh
- Log out and log back into workspace
- Check workspace URL is correct

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

## Secrets Manager Integration

### Overview

The module now supports automatic storage and retrieval of workspace URL and PAT using AWS Secrets Manager. This eliminates the need to manually pass these values after the initial setup.

### Quick Start

1. **After Pass-1 (Workspace Creation):**
   ```bash
   # Get workspace URL
   WORKSPACE_URL=$(terraform output -raw workspace_url)
   
   # Store credentials in Secrets Manager
   # ✅ NEW: Just add PAT to terraform.tfvars - Terraform handles it automatically
   # In terraform.tfvars:
   workspace_pat = "YOUR_PAT_TOKEN"
   
   # Then run:
   terraform apply  # Terraform automatically stores PAT in Secrets Manager
   ```

2. **In terraform.tfvars:**
   ```hcl
   use_secrets_manager = true  # Default
   workspace_pat = ""  # Optional - retrieved from Secrets Manager
   ```

3. **Continue with Pass-2:**
   ```bash
   terraform apply  # Automatically retrieves from Secrets Manager!
   ```

### How It Works

1. **Pass-1:** Workspace URL automatically stored in Secrets Manager
2. **Manual Step:** Create PAT, store using script (located in root folder)
3. **Pass-2:** Both workspace URL and PAT automatically retrieved from Secrets Manager
4. **No Code Changes:** No manual provider.tf changes needed between passes!

### Benefits

- ✅ No manual input required after initial setup
- ✅ Secure credential storage in AWS Secrets Manager
- ✅ Easy PAT updates without code changes
- ✅ Version control safe (no secrets in code)

### Documentation

For complete documentation, see:
- `../README_SECRETS_MANAGER.md` - Quick start guide
- `../README.md` - Main module documentation with 2-pass deployment guide

### ⚠️ Script Removed

**The `store-workspace-credentials.sh` script has been removed. Terraform now handles this automatically!**

Simply provide `workspace_pat` in `terraform.tfvars` and Terraform will automatically:
- ✅ Store the PAT in AWS Secrets Manager
- ✅ Update the secret when PAT changes
- ✅ Retrieve credentials for subsequent deployments

**No manual script or AWS CLI commands needed!**

---

## Next Steps

After successful deployment:

1. **Create Schemas** (if needed):
   - Use Databricks UI or SQL to create schemas in catalogs
   - Or use separate Terraform resources

2. **Configure Access:**
   - Add users/groups to workspace
   - Configure workspace-level permissions

3. **Deploy Workloads:**
   - Deploy notebooks, jobs, and pipelines
   - Use the created clusters and catalogs

---

## Support

For issues or questions:
1. Check this README
2. Review Terraform error messages
3. Check Databricks documentation
4. Contact your platform team

---

**Happy Deploying! 🚀**
