# ub-tf-dbx-envs

Environment deployment repository for Databricks on AWS using a three-tier repository structure:
- **Repo A** (`ub-tf-aws-databricks`): Base modules (workspace, unity-catalog, cluster, catalog)
- **Repo B** (`ub-tf-dbx-platform`): Platform module that composes Repo A modules
- **Repo C** (`ub-tf-dbx-envs`): Environment-specific deployments (this repository)

---

## 📋 Repository Structure

```
ub-tf-dbx-envs/
├── README.md                    # This file
├── terraform/                   # All Terraform code
│   ├── stag/                    # Staging environment
│   │   ├── main.tf              # Calls Repo B module
│   │   ├── variables.tf         # Environment-specific variables
│   │   ├── locals.tf            # Auto-computed values
│   │   ├── outputs.tf           # Environment outputs
│   │   ├── provider.tf          # Provider configuration
│   │   └── examples/
│   │       └── stag/
│   │           ├── terraform.tfvars.example  # Simplified example
│   │           └── EXAMPLE_DEPLOYMENT.md   # Deployment guide
│   ├── intg/                    # Integration environment
│   │   ├── main.tf              # Calls Repo B module
│   │   ├── variables.tf         # Environment-specific variables
│   │   ├── locals.tf            # Auto-computed values
│   │   ├── outputs.tf           # Environment outputs
│   │   ├── provider.tf          # Provider configuration
│   │   └── examples/
│   │       └── intg/
│   │           ├── terraform.tfvars.example  # Simplified example
│   │           └── EXAMPLE_DEPLOYMENT.md     # Deployment guide
│   └── prod/                    # Production environment
│       ├── main.tf              # Calls Repo B module
│       ├── variables.tf         # Environment-specific variables
│       ├── locals.tf            # Auto-computed values
│       ├── outputs.tf           # Environment outputs
│       ├── provider.tf          # Provider configuration
│       └── examples/
│           └── prod/
│               ├── terraform.tfvars.example  # Simplified example
│               └── EXAMPLE_DEPLOYMENT.md     # Deployment guide
```

---

## 🎯 Key Features

### Simplified Configuration
- **Auto-computed values**: Many values are automatically computed from `product_name`, `region`, and `environment`
- **Minimal input required**: Only provide essential values in `terraform.tfvars`
- **Consistent naming**: Resource names follow standardized patterns

### Auto-Computed Values
The following values are automatically computed (no need to provide in `terraform.tfvars`):

- `service` → Always `"databricks"`
- `environment` → From folder name (`stag`, `intg`, `prod`)
- `workspace_name` → `{product_name}-{env}-ws-{region}`
- `uc_metastore_name` → `{product_name}-{env}-metastore-{region}` (staging creates, intg/prod reference staging)
- `uc_metastore_region` → Same as `region`
- `uc_external_prefix` → `s3://{product_name}-dashboard-{env}-{region}/unity-catalog/`
- `prefix` → First 3 characters of `product_name`
- `catalog.storage_root` → `s3://{product_name}-dashboard-{env}-{region}/catalogs/{env}/{catalog_name}/`
- Tags: `env`, `product`, `service`, `repo`, `created_by`, `region` (only `owner` and `customer` required)

### Shared Metastore Architecture
- **Staging**: Creates Unity Catalog metastore
- **Integration & Production**: Reference staging metastore (shared across all environments)
- Metastore ID retrieved from staging outputs

### Secrets Manager Integration
- **Default behavior**: Workspace URL and PAT stored/retrieved automatically via AWS Secrets Manager
- **No manual provider configuration**: Repo B handles Databricks provider internally
- **Seamless Pass-2**: No need to manually update `provider.tf` or `main.tf`

---

## 🚀 Quick Start

### Prerequisites

1. **AWS Account**
   - AWS CLI configured
   - IAM permissions for EC2, S3, Secrets Manager, Databricks MWS API

2. **Databricks Account**
   - Databricks Account Console access
   - Pre-created MWS objects:
     - `mws_credentials_id`
     - `mws_storage_config_id`
     - `mws_network_id`
     - `mws_private_access_settings_id`

3. **AWS Infrastructure**
   - Existing VPC (`vpc_id`)
   - Private subnets (`private_subnet_ids`) - at least 2
   - Security groups (`security_group_ids`)
   - S3 bucket for root storage (`root_storage_bucket`) - or will be created
   - IAM role for cross-account access (`cross_account_role_arn`)

4. **Terraform**
   - Terraform >= 1.6.0
   - AWS Provider >= 5.60
   - Databricks Provider >= 1.51.0

5. **Pre-Deployment Setup** ⚠️ **REQUIRED BEFORE `terraform init`**
   - **Replace module source URLs:** Update `<org>` and `<tag>` placeholders in `main.tf` files
   - **Create backend S3 bucket:** Create S3 bucket for Terraform state (see `backend.tf`)
   - **Configure backend:** Update `backend.tf` with your state bucket name

### Step 0: Pre-Deployment Setup ⚠️ **REQUIRED**

Before running `terraform init`, complete these steps:

#### 1. Replace Module Source URLs

Update module source placeholders in all environment `main.tf` files:

**Files to update:**
- `terraform/stag/main.tf`
- `terraform/intg/main.tf`
- `terraform/prod/main.tf`

**Replace:**
```hcl
source = "git::https://github.com/<org>/ub-tf-dbx-platform.git?ref=<tag>"
```

**With:**
```hcl
source = "git::https://github.com/YOUR_ORG/ub-tf-dbx-platform.git?ref=v1.0.0"
```

**Note:** Also update module sources in `ub-tf-dbx-platform/main.tf` if deploying Repo B directly.

#### 2. Create Backend S3 Bucket

Create S3 bucket for Terraform state:

```bash
aws s3 mb s3://your-terraform-state-bucket --region us-east-2
aws s3api put-bucket-versioning \
  --bucket your-terraform-state-bucket \
  --versioning-configuration Status=Enabled \
  --region us-east-2
```

#### 3. Configure Backend

Update `backend.tf` in each environment with your bucket name:

```hcl
terraform {
  backend "s3" {
    bucket         = "your-terraform-state-bucket"  # Your bucket name
    key            = "dbx-envs/staging/terraform.tfstate"  # Environment-specific
    region         = "us-east-2"
    encrypt        = true
  }
}
```

### Step 1: Configure Variables

Copy the example tfvars file and update with your values:

```bash
cd terraform/stag  # Start with staging
cp examples/stag/terraform.tfvars.example terraform.tfvars
```

Edit `terraform.tfvars` - **only provide required values**:

```hcl
# Required: Identity
product_name = "damage-prevention"  # Your product name
region       = "us-east-2"          # Your AWS region

# Required: Databricks Account / MWS
databricks_account_id          = "1234567890123456"
mws_credentials_id             = "cred-stag-001"
mws_storage_config_id          = "storage-stag-001"
mws_network_id                 = "network-stag-001"
mws_private_access_settings_id = "pas-stag-001"

# Required: VPC
vpc_id             = "vpc-0123456789abcdef0"
private_subnet_ids = ["subnet-aaa111", "subnet-bbb222"]
security_group_ids = ["sg-0123abcd"]

# Required: Workspace Storage (Required by Repo A)
root_storage_bucket   = "your-root-storage-bucket"  # S3 bucket for Databricks workspace root storage
cross_account_role_arn = "arn:aws:iam::123456789012:role/databricks-cross-account-role"  # IAM role ARN

# Required: Tags (only owner and customer)
tags = {
  owner    = "data-platform-team"
  customer = "urbint"
}

# Required: Workspace Configuration
workspace = {
  pricing_tier        = "STANDARD"
  uc_storage_role_arn = "arn:aws:iam::123456789012:role/uc-role"
  
  clusters = {
    cl1 = {
      cluster_name  = "dp-stag-cluster-a"
      spark_version = "13.3.x-scala2.12"
      node_type_id  = "i3.xlarge"
      num_workers   = 2
    }
    # ... cl2, cl3
  }
  
  catalogs = {
    catalog1 = { grants = [] }
    # ... catalog2, catalog3
  }
}

# Required: Unity Catalog
aws_account_id        = "123456789012"
unity_metastore_owner = "admin@example.com"
```

**Note**: All other values (workspace_name, uc_metastore_name, S3 paths, etc.) are auto-computed!

### Step 2: Deploy Staging (Pass-1)

```bash
cd terraform/stag
terraform init
terraform plan
terraform apply
```

**This creates:**
- S3 bucket
- Databricks workspace
- Unity Catalog metastore (staging only)
- AWS Secrets Manager secret (for storing credentials)

### Step 3: Create PAT and Store in Secrets Manager

1. **Get workspace URL:**
   ```bash
   terraform output workspace_url
   ```

2. **Create PAT in Databricks UI:**
   - Log into workspace using the URL from Step 1
   - Go to **User Settings** → **Access Tokens**
   - Click **Generate New Token**
   - Copy token immediately (you won't see it again!)

3. **Store PAT in Terraform (Automatic - No Script Needed!):**
   
   **✅ NEW: Just add PAT to `terraform.tfvars` - Terraform handles the rest!**
   
   Edit your `terraform.tfvars` file and add:
   ```hcl
   workspace_pat = "dapi1234567890abcdef..."  # Your PAT from Step 2
   ```
   
   **That's it!** When you run `terraform apply` for Pass-2, Terraform will:
   - ✅ Automatically store the PAT in AWS Secrets Manager
   - ✅ Retrieve workspace URL from Secrets Manager
   - ✅ Use both for cluster and catalog creation
   
   **No manual script or AWS CLI commands needed!**

### Step 4: Deploy Staging (Pass-2)

```bash
cd ../../ub-tf-dbx-envs/terraform/stag
terraform plan
terraform apply
```

**This creates:**
- 3 Databricks clusters
- 3 Unity Catalog catalogs

### Step 5: Deploy Integration/Production

1. **Get staging metastore ID:**
   ```bash
   cd ../stag
   terraform output -raw metastore_id
   ```

2. **Configure integration/production:**
   ```bash
   cd ../intg  # or prod
   cp examples/intg/terraform.tfvars.example terraform.tfvars
   # Edit terraform.tfvars:
   # - Update all required values
   # - Add: shared_metastore_id = "<from-staging-output>"
   ```

3. **Deploy (same 2-pass process):**
   ```bash
   terraform init
   terraform plan
   terraform apply  # Pass-1
   # Create PAT and store in Secrets Manager
   terraform apply  # Pass-2
   ```

---

## 📝 Two-Pass Deployment

### Pass-1: Infrastructure Setup

**Resources Created:**
- ✅ S3 Bucket
- ✅ Databricks Workspace
- ✅ Unity Catalog Metastore (staging only)
- ✅ AWS Secrets Manager Secret

**Duration:** ~15-20 minutes

**After Pass-1:**
- Workspace URL available (from outputs)
- Metastore ID available (staging only, for sharing)
- **Manual Step Required:** Create PAT and store in Secrets Manager

### Pass-2: Compute and Data Resources

**Resources Created:**
- ✅ 3 Databricks Clusters
- ✅ 3 Unity Catalog Catalogs
- ✅ Metastore Assignment (integration/production only)

**Duration:** ~5-10 minutes

**Prerequisites:**
- PAT stored in Secrets Manager (or provided via override)
- Workspace accessible

---

## 📋 What You Need to Supply (And When)

This section details **exactly what you need to provide** and **when** you need to provide it during the deployment process.

---

### ⏰ **Timeline Overview**

```
┌─────────────────────────────────────────────────────────────┐
│ BEFORE terraform init                                        │
│ ├─ Module source URLs (replace placeholders)               │
│ ├─ Backend S3 bucket (create and configure)                │
│ └─ Backend configuration (update backend.tf)               │
└─────────────────────────────────────────────────────────────┘
                            ↓
┌─────────────────────────────────────────────────────────────┐
│ BEFORE terraform apply (Pass-1)                             │
│ ├─ Core Identity (product_name, region)                   │
│ ├─ Databricks Account / MWS IDs (5 IDs)                   │
│ ├─ VPC Configuration (vpc_id, subnets, security groups)   │
│ ├─ Workspace Storage (root_storage_bucket, cross_account)   │
│ ├─ Unity Catalog (aws_account_id, metastore_owner)         │
│ ├─ Shared Metastore (shared_metastore_id)                  │
│ ├─ Tags (owner, customer)                                   │
│ └─ Workspace Configuration (pricing_tier, clusters, etc.)  │
└─────────────────────────────────────────────────────────────┘
                            ↓
                    [Workspace Created]
                            ↓
┌─────────────────────────────────────────────────────────────┐
│ BETWEEN Pass-1 and Pass-2 (Manual Step)                    │
│ └─ Personal Access Token (PAT) - Create in Databricks UI   │
└─────────────────────────────────────────────────────────────┘
                            ↓
┌─────────────────────────────────────────────────────────────┐
│ BEFORE terraform apply (Pass-2)                             │
│ └─ workspace_pat - Add PAT to terraform.tfvars             │
└─────────────────────────────────────────────────────────────┘
```

---

### 🔧 **Before `terraform init`** ⚠️ **REQUIRED**

These must be completed **before** running `terraform init`:

#### 1. **Module Source URLs** (Required)

**What:** Replace `<org>` and `<tag>` placeholders in module source URLs

**Files to Update:**
- `terraform/stag/main.tf`
- `terraform/intg/main.tf`
- `terraform/prod/main.tf`

**Action:**
```hcl
# Replace this:
source = "git::https://github.com/<org>/ub-tf-dbx-platform.git?ref=<tag>"

# With this:
source = "git::https://github.com/YOUR_ORG/ub-tf-dbx-platform.git?ref=v1.0.0"
```

**Where to Get:** Your GitHub organization name and repository tag/branch

---

#### 2. **Backend S3 Bucket** (Required)

**What:** Create S3 bucket for Terraform state storage

**Action:**
```bash
aws s3 mb s3://your-terraform-state-bucket --region us-east-2
aws s3api put-bucket-versioning \
  --bucket your-terraform-state-bucket \
  --versioning-configuration Status=Enabled \
  --region us-east-2
```

**Where to Get:** Choose a unique bucket name (must be globally unique)

---

#### 3. **Backend Configuration** (Required)

**What:** Update `backend.tf` with your state bucket name

**Files to Update:**
- `terraform/stag/backend.tf`
- `terraform/intg/backend.tf`
- `terraform/prod/backend.tf`

**Action:**
```hcl
terraform {
  backend "s3" {
    bucket         = "your-terraform-state-bucket"  # Your bucket name
    key            = "dbx-envs/staging/terraform.tfstate"  # Environment-specific
    region         = "us-east-2"
    encrypt        = true
  }
}
```

**Where to Get:** Use the bucket name from Step 2

---

### 📝 **Before `terraform apply` (Pass-1)** ⚠️ **REQUIRED**

These must be provided in `terraform.tfvars` **before** running `terraform apply` for Pass-1:

#### 1. **Core Identity** (Required)

**What:**
```hcl
product_name = "damage-prevention"  # Your product/project name
region       = "us-east-2"          # AWS region where resources will be deployed
```

**Where to Get:**
- `product_name`: Your project/product identifier
- `region`: AWS region (e.g., `us-east-2`, `us-west-2`)

**Note:** `service` and `environment` are auto-computed (service="databricks", environment from folder name)

---

#### 2. **Databricks Account / MWS IDs** (Required - 5 IDs)

**What:**
```hcl
databricks_account_id          = "1234567890123456"  # Databricks account ID
mws_credentials_id             = "cred-123"          # MWS credentials ID
mws_storage_config_id          = "storage-123"       # MWS storage config ID
mws_network_id                 = "network-123"       # MWS network ID
mws_private_access_settings_id = "pas-123"           # MWS private access settings ID
```

**Where to Get:**
1. Log into **Databricks Account Console**
2. Navigate to **Settings** → **Account Settings**
3. Find each ID in the respective sections:
   - **Credentials** → Copy credentials ID
   - **Storage** → Copy storage configuration ID
   - **Networks** → Copy network ID
   - **Private Access Settings** → Copy private access settings ID
4. Account ID is shown in the Account Console URL or Settings page

**⚠️ Important:** These must be **pre-created** in Databricks Account Console before deployment

---

#### 3. **VPC Configuration** (Required)

**What:**
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

**Where to Get:**
1. **VPC ID:** AWS Console → VPC → Your VPCs → Copy VPC ID
2. **Subnet IDs:** AWS Console → VPC → Subnets → Filter by your VPC → Copy private subnet IDs
   - **Requirement:** At least 2 subnets in different availability zones
3. **Security Group IDs:** AWS Console → EC2 → Security Groups → Copy security group ID
   - **Requirement:** Security group must allow outbound HTTPS (443) for Databricks

**⚠️ Important:** Subnets must be **private** (not public) and in the **same region** as deployment

---

#### 4. **Workspace Storage Configuration** (Required by Repo A)

**What:**
```hcl
root_storage_bucket   = "your-root-storage-bucket"  # S3 bucket for Databricks workspace root storage
cross_account_role_arn = "arn:aws:iam::123456789012:role/databricks-cross-account-role"  # IAM role ARN
```

**Where to Get:**
1. **root_storage_bucket:** 
   - Use existing S3 bucket name, OR
   - Bucket will be created during deployment (provide desired name)
2. **cross_account_role_arn:**
   - AWS Console → IAM → Roles → Find your Databricks cross-account role → Copy ARN
   - **Requirement:** This role must be configured in Databricks Account Console (used as MWS credentials)

**⚠️ Important:** The cross-account role ARN must match the role configured in Databricks MWS credentials

---

#### 5. **Unity Catalog Configuration** (Required)

**What:**
```hcl
aws_account_id        = "123456789012"         # Your 12-digit AWS account ID
unity_metastore_owner = "admin@example.com"   # Email or service principal for UC metastore owner
```

**Where to Get:**
1. **aws_account_id:** 
   - AWS Console → Top right corner → Account ID (12 digits)
   - Or run: `aws sts get-caller-identity --query Account --output text`
2. **unity_metastore_owner:**
   - Email address of the Unity Catalog metastore owner
   - Or service principal name (e.g., `service-principal@databricks.com`)

---

#### 6. **Shared Metastore ID** (Required)

**What:**
```hcl
shared_metastore_id = "abc12345-def6-7890-ghij-klmnopqrstuv"  # ID of existing metastore
create_metastore   = false  # Must be false to use existing metastore
```

**Where to Get:**
1. **Option 1: From Databricks Account Console**
   - Log into Databricks Account Console
   - Navigate to **Unity Catalog** → **Metastores**
   - Copy the metastore ID
2. **Option 2: From Existing Deployment**
   - If metastore was created via another Terraform deployment:
     ```bash
     cd <path-to-deployment>
     terraform output -raw metastore_id
     ```

**⚠️ Important:** All environments (stag, intg, prod) use the **same existing metastore ID**

---

#### 7. **Tags** (Required - Only 2 tags needed)

**What:**
```hcl
tags = {
  owner    = "data-platform-team"  # Required: Resource owner/team name
  customer = "urbint"               # Required: Customer name
}
```

**Where to Get:**
- `owner`: Your team or individual name
- `customer`: Your organization/customer name

**Note:** The following tags are **auto-computed** (no need to provide):
- `env` = from folder name (stag/intg/prod)
- `product` = from `product_name`
- `service` = "databricks"
- `repo` = "ub-tf-dbx-platform"
- `created_by` = "terraform"
- `region` = from `region` variable

---

#### 8. **Workspace Configuration** (Required)

**What:**
```hcl
workspace = {
  pricing_tier        = "STANDARD"  # STANDARD, PREMIUM, or ENTERPRISE
  uc_storage_role_arn = "arn:aws:iam::123456789012:role/uc-role"  # IAM role for Unity Catalog
  
  # Clusters (at least one required)
  clusters = {
    cl1 = {
      cluster_name  = "dp-stag-cluster-a"  # Cluster name
      spark_version = "13.3.x-scala2.12"   # Databricks runtime version
      node_type_id  = "i3.xlarge"          # AWS instance type
      num_workers   = 2                    # Number of worker nodes
    }
    # ... more clusters
  }
  
  # Catalogs (at least one required)
  catalogs = {
    catalog1 = {
      grants = []  # Optional: List of grants
    }
    # ... more catalogs
  }
}
```

**Where to Get:**
1. **pricing_tier:** Choose based on your Databricks subscription:
   - `STANDARD` - Basic features
   - `PREMIUM` - Advanced features
   - `ENTERPRISE` - Enterprise features
2. **uc_storage_role_arn:** 
   - AWS Console → IAM → Roles → Find Unity Catalog storage role → Copy ARN
   - This role must have permissions to access S3 buckets for Unity Catalog
3. **Cluster Configuration:**
   - `cluster_name`: Choose unique names per environment
   - `spark_version`: Check available versions in Databricks (e.g., `13.3.x-scala2.12`)
   - `node_type_id`: Check available instance types in your region (e.g., `i3.xlarge`, `m5.xlarge`)
   - `num_workers`: Number of worker nodes (minimum 0 for single-node, typically 2+)
4. **Catalog Configuration:**
   - `storage_root`: Auto-computed as `s3://{bucket}/catalogs/{env}/{catalog_name}/`
   - `grants`: Optional list of permissions (see examples)

**Note:** The following are **auto-computed** (no need to provide):
- `workspace_name` = `{product_name}-{env}-ws-{region}`
- `uc_metastore_name` = `{product_name}-{env}-metastore-{region}` (for reference only)
- `uc_metastore_region` = same as `region`
- `uc_external_prefix` = `s3://{product_name}-dashboard-{env}-{region}/unity-catalog/`
- `catalog.storage_root` = `s3://{product_name}-dashboard-{env}-{region}/catalogs/{env}/{catalog_name}/`

---

### 🔑 **Between Pass-1 and Pass-2** (Manual Step)

#### **Personal Access Token (PAT)** (Required)

**What:** Create a Databricks Personal Access Token

**When:** After Pass-1 completes (workspace is created)

**Action:**
1. **Get workspace URL:**
   ```bash
   terraform output workspace_url
   ```

2. **Log into Databricks Workspace:**
   - Use the workspace URL from Step 1
   - Log in with your Databricks account

3. **Create PAT:**
   - Go to **User Settings** → **Access Tokens**
   - Click **Generate New Token**
   - Name: `terraform-<environment>` (e.g., `terraform-stag`)
   - Lifetime: Set appropriate expiration (e.g., 90 days)
   - Permissions: Ensure it has:
     - ✅ Cluster creation permissions
     - ✅ Unity Catalog admin permissions
   - Click **Generate**
   - **Copy the token immediately** (you won't see it again!)

**Where to Get:** Databricks Workspace UI (after workspace is created in Pass-1)

---

### 📝 **Before `terraform apply` (Pass-2)** ⚠️ **REQUIRED**

#### **Add PAT to terraform.tfvars** (Required)

**What:**
```hcl
workspace_pat = "dapi1234567890abcdef..."  # Your PAT from previous step
use_secrets_manager = true  # Default: true - enables automatic storage
```

**Action:**
1. Edit `terraform.tfvars`
2. Add `workspace_pat` with the PAT you created
3. Save the file

**What Happens:** When you run `terraform apply` for Pass-2:
- ✅ Terraform automatically stores the PAT in AWS Secrets Manager
- ✅ Terraform retrieves workspace URL from Secrets Manager
- ✅ Terraform uses both for cluster and catalog creation

**Where to Get:** From the PAT you created in the previous step

---

## 🔧 Configuration Details

### Required Variables

**Identity:**
- `product_name` - Your product name
- `region` - AWS region

**Databricks:**
- `databricks_account_id` - Databricks account ID
- `mws_credentials_id` - MWS credentials ID
- `mws_storage_config_id` - MWS storage config ID
- `mws_network_id` - MWS network ID
- `mws_private_access_settings_id` - MWS private access settings ID

**VPC:**
- `vpc_id` - VPC ID
- `private_subnet_ids` - List of private subnet IDs (at least 2)
- `security_group_ids` - List of security group IDs

**Workspace Storage (Required by Repo A):**
- `root_storage_bucket` - S3 bucket name used as root storage bucket for Databricks workspace
- `cross_account_role_arn` - IAM role ARN used for cross-account access (required for Databricks workspace)

**Tags:**
- `owner` - Resource owner (required)
- `customer` - Customer name (required)

**Workspace:**
- `pricing_tier` - STANDARD, PREMIUM, or ENTERPRISE
- `uc_storage_role_arn` - IAM role ARN for Unity Catalog
- `clusters` - Map of cluster configurations (3 clusters)
- `catalogs` - Map of catalog configurations (3 catalogs)

**Unity Catalog:**
- `aws_account_id` - AWS account ID
- `unity_metastore_owner` - UC metastore owner email

**All Environments:**
- `shared_metastore_id` - ID of existing Unity Catalog metastore (all environments use the same existing metastore)

### Auto-Computed Values

The following are automatically computed from `product_name`, `region`, and `environment`:

| Value | Auto-Computed As |
|-------|-----------------|
| `service` | `"databricks"` |
| `environment` | From folder name (`stag`, `intg`, `prod`) |
| `workspace_name` | `{product_name}-{env}-ws-{region}` |
| `uc_metastore_name` | `{product_name}-{env}-metastore-{region}` (staging creates, intg/prod reference staging) |
| `uc_metastore_region` | Same as `region` |
| `uc_external_prefix` | `s3://{product_name}-dashboard-{env}-{region}/unity-catalog/` |
| `prefix` | First 3 chars of `product_name` |
| `catalog.storage_root` | `s3://{product_name}-dashboard-{env}-{region}/catalogs/{env}/{catalog_name}/` |
| Tags: `env`, `product`, `service`, `repo`, `created_by`, `region` | Auto-computed |

---

## 📚 Detailed Documentation

For environment-specific deployment guides, see:

- **Staging**: `terraform/stag/examples/stag/EXAMPLE_DEPLOYMENT.md`
- **Integration**: `terraform/intg/examples/intg/EXAMPLE_DEPLOYMENT.md`
- **Production**: `terraform/prod/examples/prod/EXAMPLE_DEPLOYMENT.md`

For environment-specific READMEs, see:

- **Staging**: `terraform/stag/README.md`
- **Integration**: `terraform/intg/README.md`
- **Production**: `terraform/prod/README.md`

---

## 🔐 Secrets Manager

**Default Behavior (Recommended):**
- Workspace URL and PAT stored automatically in AWS Secrets Manager after Pass-1
- Terraform retrieves credentials automatically in Pass-2
- No manual `provider.tf` updates needed

**Secret Name Format:**
```
{product_name}-{environment}-{region}-databricks-workspace
```

**Example:**
```
damage-prevention-stag-us-east-2-databricks-workspace
```

**Manual Override (Optional):**
If you need to override Secrets Manager:
```hcl
use_secrets_manager   = false
workspace_url_override = "https://..."
workspace_pat_override = "dapi..."
```

---

## 🏗️ Architecture

### Resource Dependencies

```
S3 Bucket
    │
    └─> Workspace (uses S3 for root storage)
            │
            ├─> Unity Catalog Metastore (created in staging)
            │       │
            │       └─> Catalogs (created in Pass-2)
            │
            ├─> Clusters (created in Pass-2)
            │
            └─> Secrets Manager Secret (stores workspace credentials)
```

### Shared Metastore Model

```
┌─────────────┐
│   Staging   │  Creates metastore
│             │  ──────────────────┐
└─────────────┘                    │
                                   │
┌─────────────┐                    │
│ Integration │  References ───────┘
│             │  staging metastore
└─────────────┘
                                   │
┌─────────────┐                    │
│ Production  │  References ───────┘
│             │  staging metastore
└─────────────┘
```

**Key Points:**
- Staging creates the metastore
- Integration and production reference the staging metastore
- All environments share the same Unity Catalog metastore
- Each environment has its own workspace, clusters, and catalogs

---

## 📊 Outputs

After deployment, the following outputs are available:

| Output | Description |
|--------|-------------|
| `s3_bucket_name` | S3 bucket name |
| `workspace_url` | Databricks workspace URL |
| `workspace_id` | Databricks workspace ID |
| `metastore_id` | Unity Catalog metastore ID (staging only) |
| `cluster_ids` | Map of cluster IDs |
| `catalog_names` | Map of catalog names |

**View outputs:**
```bash
terraform output
terraform output -raw metastore_id
terraform output -json cluster_ids
```

---

## ⚠️ Important Notes

1. **Deploy Staging First**: Staging creates the metastore that integration and production reference
2. **Get Metastore ID**: Before deploying integration/production, get metastore ID from staging:
   ```bash
   cd terraform/stag
   terraform output -raw metastore_id
   ```
3. **2-Pass Deployment**: Always deploy in 2 passes (Pass-1: infrastructure, Pass-2: compute/data)
4. **PAT Creation**: PAT must be created manually in Databricks UI between Pass-1 and Pass-2
5. **Secrets Manager**: Default behavior stores/retrieves credentials automatically
6. **No Schema Creation**: Catalogs are created without schemas (create manually in Databricks UI)
7. **S3 Bucket**: All S3 paths use the bucket created during deployment
8. **Unique Catalog Names**: Integration and production catalogs must have unique names (e.g., `intg_catalog1`, `prod_catalog1`)

---

## 🔍 Troubleshooting

### Common Issues

**Issue: Module source not found**
- **Solution**: Update module source URLs in `main.tf` with actual GitHub organization and tag

**Issue: Missing metastore_id for integration/production**
- **Solution**: Deploy staging first and get metastore ID from outputs

**Issue: PAT not found in Secrets Manager**
- **Solution**: 
  - Create PAT in workspace UI
  - Add `workspace_pat` to `terraform.tfvars` and run `terraform apply` - Terraform automatically stores it in Secrets Manager

**Issue: Catalog names conflict**
- **Solution**: Use unique catalog names per environment (e.g., `intg_catalog1`, `prod_catalog1`)

---

## 📖 Additional Resources

- **Repo A** (`ub-tf-aws-databricks`): Base modules documentation
- **Repo B** (`ub-tf-dbx-platform`): Platform module documentation
- **Testing Guide**: See `TESTING_WITHOUT_DEPLOYMENT.md` in root directory

---

**Last Updated:** 2024  
**Terraform Version:** >= 1.6.0
