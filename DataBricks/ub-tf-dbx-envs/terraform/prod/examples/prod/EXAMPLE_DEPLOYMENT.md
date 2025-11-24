# Production Environment - Complete Deployment Guide

This guide provides step-by-step instructions to deploy the Production Databricks environment. **⚠️ IMPORTANT: Production environment MUST be deployed AFTER staging environment** because it uses the staging metastore.

---

## 📋 Table of Contents

1. [Prerequisites](#prerequisites)
2. [Step 0: Deploy Staging Environment First](#step-0-deploy-staging-environment-first)
3. [Step 1: Prepare Configuration](#step-1-prepare-configuration)
4. [Step 2: PASS-1 - Deploy Infrastructure](#step-2-pass-1---deploy-infrastructure)
5. [Step 3: Create and Store PAT](#step-3-create-and-store-pat)
6. [Step 4: PASS-2 - Deploy Compute & Data Resources](#step-4-pass-2---deploy-compute--data-resources)
7. [Step 5: Verify Deployment](#step-5-verify-deployment)
8. [Troubleshooting](#troubleshooting)

---

## Prerequisites

Before starting, ensure you have:

### 1. **Staging Environment Deployed** ⚠️ **REQUIRED**
- ✅ Staging environment must be deployed first
- ✅ Staging metastore must be created and accessible
- ✅ Staging metastore ID available from staging outputs

### 2. **AWS Access**
- ✅ AWS CLI configured with appropriate credentials
- ✅ IAM permissions for:
  - EC2 (VPC, subnets, security groups)
  - S3 (bucket creation, Secrets Manager)
  - Databricks MWS API access

### 3. **Databricks Account**
- ✅ Databricks Account Console access
- ✅ Pre-created MWS objects:
  - `mws_credentials_id` - Cross-account IAM role credentials
  - `mws_storage_config_id` - Root storage bucket configuration
  - `mws_network_id` - VPC network configuration
  - `mws_private_access_settings_id` - Private access settings

### 4. **AWS Infrastructure**
- ✅ Existing VPC (`vpc_id`)
- ✅ Private subnets (`private_subnet_ids`) - at least 2
- ✅ Security groups (`security_group_ids`)

### 5. **Terraform**
- ✅ Terraform >= 1.6.0 installed
- ✅ AWS Provider >= 5.60
- ✅ Databricks Provider >= 1.51.0

### 6. **Terraform State Backend**
- ✅ S3 bucket for Terraform state (or create one)

---

## Step 0: Deploy Staging Environment First

**⚠️ CRITICAL:** Production environment uses the staging metastore. You MUST deploy staging first.

### 0.1 Deploy Staging Environment

Follow the staging deployment guide:
```bash
cd ub-tf-dbx-envs/terraform/stag
# Follow staging EXAMPLE_DEPLOYMENT.md to deploy staging
terraform apply
```

### 0.2 Get Staging Metastore ID

After staging deployment completes, get the metastore ID:

```bash
cd ub-tf-dbx-envs/terraform/stag
STAGING_METASTORE_ID=$(terraform output -raw metastore_id)
echo "Staging Metastore ID: $STAGING_METASTORE_ID"
```

**Save this ID** - you'll need it in Step 1.

**Example output:**
```
Staging Metastore ID: abc12345-def6-7890-ghij-klmnopqrstuv
```

---

## Step 1: Prepare Configuration

### 1.1 Copy Example Configuration

```bash
cd ub-tf-dbx-envs/terraform/prod
cp examples/prod/terraform.tfvars.example terraform.tfvars
```

### 1.2 Update `terraform.tfvars`

Open `terraform.tfvars` and update all values marked with `# CHANGE`:

#### Identity Section
```hcl
product_name = "damage-prevention"  # Your product name
region       = "us-east-2"           # Your AWS region
```

#### Databricks Account / MWS Section
```hcl
databricks_account_id          = "1234567890123456"   # Your Databricks account ID
mws_credentials_id             = "cred-prod-001"      # Your MWS credentials ID
mws_storage_config_id          = "storage-prod-001"  # Your MWS storage config ID
mws_network_id                 = "network-prod-001"  # Your MWS network ID
mws_private_access_settings_id = "pas-prod-001"      # Your MWS PAS ID
```

#### VPC Configuration
```hcl
vpc_id = "vpc-0123456789abcdef0"  # Your VPC ID

private_subnet_ids = [
  "subnet-aaa111",  # Your private subnet IDs (at least 2)
  "subnet-bbb222",
]

security_group_ids = [
  "sg-0123abcd",  # Your security group IDs
]
```

#### Tags Section
```hcl
tags = {
  owner      = "data-platform-team"  # Your team/owner
  env        = "prod"                 # Must be "prod"
  product    = "damage-prevention"    # Match product_name above
  customer   = "urbint"               # Your customer name
  region     = "us-east-2"           # Match region above
  # ... other tags
}
```

#### Workspace Configuration
```hcl
workspace = {
  workspace_name = "dp-prod-ws-us-east-2"  # Format: {product}-{env}-ws-{region}
  pricing_tier   = "PREMIUM"              # STANDARD, PREMIUM, or ENTERPRISE (production typically uses PREMIUM)
  
  # Unity Catalog Metastore Configuration
  # IMPORTANT: Production uses SHARED metastore from staging
  uc_metastore_name   = "dp-stag-metastore-us-east-2"  # References staging metastore name
  uc_metastore_region = "us-east-2"                     # Match your region
  uc_external_prefix  = "s3://dp-shared-uc/"            # Your S3 prefix for UC
  uc_storage_role_arn = "arn:aws:iam::123456789012:role/uc-role"  # IAM role ARN for UC
  
  # Update cluster configurations
  clusters = {
    cl1 = {
      cluster_name  = "dp-prod-cluster-a"  # Your cluster name
      spark_version = "13.3.x-scala2.12"   # Spark version
      node_type_id  = "i3.xlarge"          # Instance type
      num_workers   = 2                    # Number of workers
    }
    cl2 = {
      cluster_name  = "dp-prod-cluster-b"
      spark_version = "13.3.x-scala2.12"
      node_type_id  = "i3.2xlarge"
      num_workers   = 3
    }
    cl3 = {
      cluster_name  = "dp-prod-cluster-c"
      spark_version = "13.3.x-scala2.12"
      node_type_id  = "m5.xlarge"
      num_workers   = 4
    }
  }
  
  # Update catalog storage roots
  # IMPORTANT: Use unique catalog names (prod_catalog1, prod_catalog2, prod_catalog3)
  # to avoid conflicts with staging/integration catalogs in the shared metastore
  catalogs = {
    prod_catalog1 = {
      storage_root = "s3://dp-shared-uc/prod/catalog1/"  # Your S3 path
      grants       = []                                   # Optional grants
    }
    prod_catalog2 = {
      storage_root = "s3://dp-shared-uc/prod/catalog2/"
      grants = [
        {
          principal  = "data-engineers"                   # Principal name
          privileges = ["USE_CATALOG"]
        }
      ]
    }
    prod_catalog3 = {
      storage_root = "s3://dp-shared-uc/prod/catalog3/"
      grants = [
        {
          principal  = "data-engineers"
          privileges = ["USE_CATALOG"]
        }
      ]
    }
  }
}
```

#### Unity Catalog Variables
```hcl
aws_account_id        = "123456789012"        # Your AWS account ID
unity_metastore_owner = "admin@example.com"   # UC metastore owner email
prefix                = "dp"                  # Resource prefix
```

#### ⭐ **Shared Metastore Configuration** (CRITICAL)

```hcl
# IMPORTANT: Production environment uses staging metastore
# 1. Deploy staging environment first to create metastore
# 2. Get metastore_id from staging outputs: terraform output -raw metastore_id
# 3. Set shared_metastore_id below to the staging metastore ID
# 4. Set create_metastore = false to prevent creating a new metastore

shared_metastore_id = "abc12345-def6-7890-ghij-klmnopqrstuv"  # CHANGE: Get from staging outputs
create_metastore   = false  # Must be false to use shared metastore from staging
```

**⚠️ CRITICAL:** Replace `shared_metastore_id` with the staging metastore ID from Step 0.2.

### 1.3 Update Backend Configuration

Edit `backend.tf` (if it exists):

```hcl
terraform {
  backend "s3" {
    bucket         = "your-terraform-state-bucket"  # CHANGE: Your state bucket
    key            = "dbx-envs/production/terraform.tfstate"
    region         = "us-east-2"                     # CHANGE: Your region
    encrypt        = true
  }
}
```

**Note:** If the S3 bucket doesn't exist, create it first:
```bash
aws s3 mb s3://your-terraform-state-bucket --region us-east-2
```

---

## Step 2: PASS-1 - Deploy Infrastructure

This pass creates the S3 bucket, Databricks workspace, and assigns the staging metastore to the production workspace.

### 2.1 Initialize Terraform

```bash
cd ub-tf-dbx-envs/terraform/prod
terraform init
```

**Expected output:**
```
Initializing the backend...
Initializing provider plugins...
Terraform has been successfully initialized!
```

### 2.2 Review the Plan

```bash
terraform plan
```

**What to expect:**
- S3 bucket creation
- Databricks workspace creation
- **Metastore assignment** (NOT creation - uses staging metastore)
- AWS Secrets Manager secret creation (for workspace credentials)

**Review the plan carefully** to ensure:
- ✅ `shared_metastore_id` matches staging metastore ID
- ✅ `create_metastore = false` (no new metastore creation)
- ✅ Workspace name is correct
- ✅ All MWS IDs are correct

### 2.3 Apply Pass-1

```bash
terraform apply
```

Type `yes` when prompted, or use:
```bash
terraform apply -auto-approve
```

**This will take 15-20 minutes** (workspace creation is the longest step).

### 2.4 Capture Outputs

After Pass-1 completes successfully, capture the workspace URL:

```bash
# Get workspace URL
WORKSPACE_URL=$(terraform output -raw workspace_url)
echo "Workspace URL: $WORKSPACE_URL"

# View all outputs
terraform output
```

**Expected outputs:**
```
workspace_id = "1234567890123456"
workspace_url = "https://dbc-xyz12345-6789.cloud.databricks.com"
metastore_id = "abc12345-def6-7890-ghij-klmnopqrstuv"  # Same as staging
s3_bucket_name = "dp-damage-prevention-prod-us-east-2-s3"
```

**✅ What happened automatically:**
- Workspace URL and ID were automatically stored in AWS Secrets Manager
- Secret name: `damage-prevention-prod-us-east-2-databricks-workspace`
- Staging metastore was assigned to production workspace
- No manual action needed for this step!

**✅ Verify metastore assignment:**
- The `metastore_id` output should match the staging metastore ID
- This confirms the production workspace is using the shared staging metastore

---

## Step 3: Create and Store PAT

**⚠️ IMPORTANT:** This is a manual step that must be completed before Pass-2.

### 3.1 Create PAT in Databricks Workspace

1. **Log into the workspace:**
   - Open the workspace URL from Pass-1 output
   - Example: `https://dbc-xyz12345-6789.cloud.databricks.com`
   - Log in with your Databricks account credentials

2. **Navigate to Access Tokens:**
   - Click on your **user icon** (top right corner)
   - Select **User Settings**
   - Click on **Access Tokens** tab

3. **Generate new token:**
   - Click **Generate New Token**
   - Add a comment: `Terraform automation for production`
   - Set lifetime:
     - **Recommended:** 90 days (or custom based on your policy)
     - **Minimum:** 30 days
   - Click **Generate**

4. **Copy the token:**
   - ⚠️ **CRITICAL:** Copy the token immediately
   - You won't be able to see it again!
   - Example format: `dapi1234567890abcdef...`
   - Save it securely (you'll need it in the next step)

### 3.2 Store PAT in Secrets Manager

You have three options. Choose the one that works best for you:

#### Option A: Using Helper Script (Recommended)

```bash
# Navigate to Repo B root folder
cd ../../../ub-tf-dbx-platform

# Run the helper script
./store-workspace-credentials.sh \
  "$WORKSPACE_URL" \
  "dapi1234567890abcdef..." \
  "damage-prevention" \
  "prod" \
  "us-east-2"
```

**Expected output:**
```
Secret damage-prevention-prod-us-east-2-databricks-workspace already exists. Updating...
Secret updated successfully!

Secret Name: damage-prevention-prod-us-east-2-databricks-workspace
Workspace URL: https://dbc-xyz12345-6789.cloud.databricks.com
PAT: [REDACTED]
```

#### Option B: Using AWS CLI

```bash
SECRET_NAME="damage-prevention-prod-us-east-2-databricks-workspace"
WORKSPACE_URL="https://dbc-xyz12345-6789.cloud.databricks.com"
WORKSPACE_PAT="dapi1234567890abcdef..."

# Get existing secret to preserve workspace_id
EXISTING_SECRET=$(aws secretsmanager get-secret-value \
  --secret-id "$SECRET_NAME" \
  --region us-east-2 \
  --query SecretString \
  --output text)

# Extract workspace_id from existing secret
WORKSPACE_ID=$(echo $EXISTING_SECRET | jq -r '.workspace_id')

# Update secret with PAT
aws secretsmanager update-secret \
  --secret-id "$SECRET_NAME" \
  --secret-string "{\"workspace_id\":\"$WORKSPACE_ID\",\"workspace_url\":\"$WORKSPACE_URL\",\"workspace_pat\":\"$WORKSPACE_PAT\",\"updated_at\":\"$(date -u +%Y-%m-%dT%H:%M:%SZ)\"}" \
  --region us-east-2
```

#### Option C: Using AWS Console

1. **Go to AWS Secrets Manager:**
   - Open AWS Console
   - Navigate to **Secrets Manager**
   - Find secret: `damage-prevention-prod-us-east-2-databricks-workspace`

2. **Retrieve current secret:**
   - Click on the secret name
   - Click **Retrieve secret value**
   - Click **Edit**

3. **Update the JSON:**
   ```json
   {
     "workspace_id": "1234567890123456",
     "workspace_url": "https://dbc-xyz12345-6789.cloud.databricks.com",
     "workspace_pat": "dapi1234567890abcdef...",
     "updated_at": "2024-01-01T12:00:00Z"
   }
   ```
   - Replace `workspace_pat` with your PAT token
   - Update `updated_at` with current timestamp

4. **Save:**
   - Click **Save**

### 3.3 Verify PAT is Stored

```bash
# Verify secret exists and has PAT
aws secretsmanager get-secret-value \
  --secret-id "damage-prevention-prod-us-east-2-databricks-workspace" \
  --region us-east-2 \
  --query SecretString \
  --output text | jq -r '.workspace_pat'
```

**Expected:** Should return your PAT (not "MANUAL_UPDATE_REQUIRED")

---

## Step 4: PASS-2 - Deploy Compute & Data Resources

This pass creates the compute clusters and Unity Catalog catalogs in the shared staging metastore.

### 4.1 Return to Terraform Directory

```bash
cd ub-tf-dbx-envs/terraform/prod
```

### 4.2 Review the Plan

```bash
terraform plan
```

**What to expect:**
- 3 compute clusters creation
- 3 Unity Catalog catalogs creation (in staging metastore)
- No changes to workspace or metastore (already created/assigned in Pass-1)

**Note:** Terraform will automatically retrieve workspace URL and PAT from Secrets Manager - no need to set them in terraform.tfvars!

**Important:** Verify catalog names are unique:
- Should see: `prod_catalog1`, `prod_catalog2`, `prod_catalog3`
- Should NOT see: `catalog1`, `catalog2`, `catalog3` (those are staging catalogs)
- Should NOT see: `intg_catalog1`, `intg_catalog2`, `intg_catalog3` (those are integration catalogs)

### 4.3 Apply Pass-2

```bash
terraform apply
```

Type `yes` when prompted.

**This will take 5-10 minutes** (cluster creation is faster than workspace creation).

### 4.4 Verify Outputs

```bash
terraform output
```

**Expected outputs:**
```
s3_bucket_name = "dp-damage-prevention-prod-us-east-2-s3"
workspace_url = "https://dbc-xyz12345-6789.cloud.databricks.com"
workspace_id = "1234567890123456"
metastore_id = "abc12345-def6-7890-ghij-klmnopqrstuv"  # Same as staging
cluster_ids = {
  "cl1" = "1234-567890-abc123"
  "cl2" = "1234-567890-def456"
  "cl3" = "1234-567890-ghi789"
}
catalog_names = {
  "prod_catalog1" = "prod_catalog1"
  "prod_catalog2" = "prod_catalog2"
  "prod_catalog3" = "prod_catalog3"
}
```

**✅ What happened automatically:**
- Workspace URL and PAT were automatically retrieved from Secrets Manager
- No manual provider.tf changes needed!
- All clusters created successfully
- All catalogs created in the **shared staging metastore**

---

## Step 5: Verify Deployment

### 5.1 Verify in Terraform

```bash
# View all outputs
terraform output

# Check specific resources
terraform output workspace_url
terraform output metastore_id  # Should match staging metastore ID
terraform output cluster_ids
terraform output catalog_names
```

### 5.2 Verify in Databricks Workspace

1. **Log into workspace:**
   - Use the workspace URL from outputs
   - Example: `https://dbc-xyz12345-6789.cloud.databricks.com`

2. **Verify clusters:**
   - Go to **Compute** → **Clusters**
   - You should see 3 clusters:
     - `dp-prod-cluster-a`
     - `dp-prod-cluster-b`
     - `dp-prod-cluster-c`
   - All should be in **Running** state

3. **Verify catalogs:**
   - Go to **Data** → **Catalogs**
   - You should see **9 catalogs total** (3 from staging + 3 from integration + 3 from production):
     - **Staging catalogs:** `catalog1`, `catalog2`, `catalog3`
     - **Integration catalogs:** `intg_catalog1`, `intg_catalog2`, `intg_catalog3`
     - **Production catalogs:** `prod_catalog1`, `prod_catalog2`, `prod_catalog3`
   - **Note:** All 9 catalogs are in the same metastore (staging metastore)
   - **Note:** Catalogs are created without schemas (schemas must be created manually)

4. **Verify metastore:**
   - Go to **Settings** → **Unity Catalog**
   - Verify metastore `dp-stag-metastore-us-east-2` is assigned
   - This is the **same metastore** used by staging and integration workspaces
   - Check metastore region and configuration

### 5.3 Verify in AWS

1. **S3 Bucket:**
   ```bash
   aws s3 ls | grep damage-prevention-prod
   ```
   Should show: `dp-damage-prevention-prod-us-east-2-s3`

2. **Secrets Manager:**
   ```bash
   aws secretsmanager describe-secret \
     --secret-id "damage-prevention-prod-us-east-2-databricks-workspace" \
     --region us-east-2
   ```
   Should show the secret exists and is accessible

### 5.4 Verify Shared Metastore

**Verify all workspaces use the same metastore:**

```bash
# Get staging metastore ID
cd ../stag
STAGING_METASTORE_ID=$(terraform output -raw metastore_id)
echo "Staging Metastore ID: $STAGING_METASTORE_ID"

# Get production metastore ID
cd ../prod
PROD_METASTORE_ID=$(terraform output -raw metastore_id)
echo "Production Metastore ID: $PROD_METASTORE_ID"

# They should match!
if [ "$STAGING_METASTORE_ID" = "$PROD_METASTORE_ID" ]; then
  echo "✅ SUCCESS: Both environments use the same metastore!"
else
  echo "❌ ERROR: Metastore IDs don't match!"
fi
```

---

## Troubleshooting

### Issue 1: Metastore ID Not Found

**Error:**
```
Error: shared_metastore_id is required when create_metastore = false
```

**Solution:**
1. Deploy staging environment first (Step 0)
2. Get staging metastore ID:
   ```bash
   cd ub-tf-dbx-envs/terraform/stag
   terraform output -raw metastore_id
   ```
3. Update production `terraform.tfvars`:
   ```hcl
   shared_metastore_id = "<staging-metastore-id>"
   create_metastore   = false
   ```

---

### Issue 2: Catalog Name Conflict

**Error:**
```
Error: catalog 'catalog1' already exists in metastore
```

**Solution:**
- Use unique catalog names in production
- Current configuration uses: `prod_catalog1`, `prod_catalog2`, `prod_catalog3`
- If you need different names, update `terraform.tfvars`:
  ```hcl
  catalogs = {
    my_unique_catalog1 = { ... }
    my_unique_catalog2 = { ... }
  }
  ```

---

### Issue 3: Metastore Assignment Failed

**Error:**
```
Error: cannot assign metastore to workspace
```

**Solution:**
1. Verify staging metastore exists:
   ```bash
   cd ub-tf-dbx-envs/terraform/stag
   terraform output metastore_id
   ```

2. Verify metastore ID is correct in production `terraform.tfvars`

3. Ensure production workspace is created first (Pass-1)

4. Ensure PAT is stored in Secrets Manager (required for Pass-2)

---

### Issue 4: Terraform Init Fails - Backend Bucket Not Found

**Error:**
```
Error: error loading state: NoSuchBucket: The specified bucket does not exist
```

**Solution:**
```bash
# Create the S3 bucket for Terraform state
aws s3 mb s3://your-terraform-state-bucket --region us-east-2

# Enable versioning (recommended)
aws s3api put-bucket-versioning \
  --bucket your-terraform-state-bucket \
  --versioning-configuration Status=Enabled

# Re-run terraform init
terraform init
```

---

### Issue 5: Pass-1 Fails - Invalid VPC/Subnet IDs

**Error:**
```
Error: InvalidParameterValueException: Invalid subnet ID
```

**Solution:**
1. Verify VPC and subnet IDs exist:
   ```bash
   aws ec2 describe-vpcs --vpc-ids vpc-0123456789abcdef0
   aws ec2 describe-subnets --subnet-ids subnet-aaa111 subnet-bbb222
   ```

2. Ensure subnets are in the correct region
3. Verify subnets are private subnets (not public)
4. Check security group IDs are valid

---

### Issue 6: Pass-2 Fails - PAT Not Found

**Error:**
```
Error: authentication token not found
```

**Solution:**

1. **Verify PAT is stored in Secrets Manager:**
   ```bash
   aws secretsmanager get-secret-value \
     --secret-id "damage-prevention-prod-us-east-2-databricks-workspace" \
     --region us-east-2 \
     --query SecretString \
     --output text | jq -r '.workspace_pat'
   ```
   Should return your PAT (not "MANUAL_UPDATE_REQUIRED")

2. **If PAT is missing:**
   - Go back to Step 3 and store the PAT
   - Use one of the three methods (script, CLI, or Console)

3. **If PAT is invalid:**
   - Create a new PAT in workspace UI
   - Update Secrets Manager with the new PAT
   - Re-run `terraform apply`

---

### Issue 7: Pass-2 Fails - Cannot Create Clusters

**Error:**
```
Error: cannot create cluster: insufficient permissions
```

**Solution:**
1. Verify workspace is accessible:
   - Log into workspace URL
   - Ensure workspace is in **Running** state

2. Check PAT permissions:
   - PAT should have **Full Access** or at least:
     - **Clusters: Create, Manage, Use**
     - **Unity Catalog: Use**

3. Verify cluster configuration:
   - Check instance types are available in your region
   - Verify spark version is valid
   - Check number of workers is reasonable

---

### Issue 8: Pass-2 Fails - Cannot Create Catalogs

**Error:**
```
Error: cannot create catalog: catalog already exists
```

**Solution:**
1. Verify catalog names are unique:
   - Production should use: `prod_catalog1`, `prod_catalog2`, `prod_catalog3`
   - Staging uses: `catalog1`, `catalog2`, `catalog3`
   - Integration uses: `intg_catalog1`, `intg_catalog2`, `intg_catalog3`

2. Check if catalogs already exist in staging metastore:
   - Log into staging workspace
   - Go to **Data** → **Catalogs**
   - Verify catalog names don't conflict

3. If conflict exists:
   - Update production `terraform.tfvars` with different catalog names
   - Re-run `terraform apply`

---

### Debug Commands

```bash
# Check Terraform state
terraform state list

# View specific resource
terraform state show module.dbx_platform.module.workspace

# Refresh state
terraform refresh

# Validate configuration
terraform validate

# Check provider versions
terraform version

# Verify Secrets Manager secret
aws secretsmanager get-secret-value \
  --secret-id "damage-prevention-prod-us-east-2-databricks-workspace" \
  --region us-east-2 \
  --query SecretString \
  --output text | jq .
```

---

## Quick Reference

### Deployment Order

1. ✅ Deploy staging environment first
2. ✅ Get staging metastore ID
3. ✅ Update production `terraform.tfvars` with staging metastore ID
4. ✅ Deploy production environment (Pass-1)
5. ✅ Create and store PAT
6. ✅ Deploy production environment (Pass-2)

### Key Files

- `main.tf` - Calls Repo B module
- `variables.tf` - Input variable definitions
- `outputs.tf` - Output values
- `provider.tf` - AWS provider configuration
- `terraform.tfvars` - Your configuration (copy from `examples/prod/terraform.tfvars.example`)

### Important Variables

- `shared_metastore_id` - Staging metastore ID (from staging outputs) ⭐
- `create_metastore = false` - Use shared metastore ⭐
- `workspace.catalogs` - Use unique catalog names (e.g., `prod_catalog1`) ⭐

### Secrets Manager Secret Name

- Format: `{product_name}-{environment}-{region}-databricks-workspace`
- Example: `damage-prevention-prod-us-east-2-databricks-workspace`

---

## Additional Resources

- **Production README**: [`../README.md`](../README.md)
- **Staging Deployment Guide**: [`../../stag/examples/stag/EXAMPLE_DEPLOYMENT.md`](../../stag/examples/stag/EXAMPLE_DEPLOYMENT.md)
- **Integration Deployment Guide**: [`../../intg/examples/intg/EXAMPLE_DEPLOYMENT.md`](../../intg/examples/intg/EXAMPLE_DEPLOYMENT.md)
- **Example Configuration**: [`terraform.tfvars.example`](./terraform.tfvars.example)
- **Repo B Documentation**: [`../../../../ub-tf-dbx-platform/README.md`](../../../../ub-tf-dbx-platform/README.md)

---

**Last Updated**: 2024  
**Environment**: Production  
**Terraform Version**: >= 1.6.0  
**⚠️ Remember**: Always deploy staging first!
