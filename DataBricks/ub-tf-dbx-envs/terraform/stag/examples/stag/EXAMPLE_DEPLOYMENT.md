# Staging Environment - Complete Deployment Guide

This guide provides step-by-step instructions to deploy the Staging Databricks environment. Follow these steps in order to successfully deploy your infrastructure.

---

## 📋 Table of Contents

1. [Prerequisites](#prerequisites)
2. [Step 1: Prepare Configuration](#step-1-prepare-configuration)
3. [Step 2: PASS-1 - Deploy Infrastructure](#step-2-pass-1---deploy-infrastructure)
4. [Step 3: Create and Store PAT](#step-3-create-and-store-pat)
5. [Step 4: PASS-2 - Deploy Compute & Data Resources](#step-4-pass-2---deploy-compute--data-resources)
6. [Step 5: Verify Deployment](#step-5-verify-deployment)
7. [Troubleshooting](#troubleshooting)

---

## Prerequisites

Before starting, ensure you have:

### 1. **AWS Access**
- ✅ AWS CLI configured with appropriate credentials
- ✅ IAM permissions for:
  - EC2 (VPC, subnets, security groups)
  - S3 (bucket creation, Secrets Manager)
  - Databricks MWS API access

### 2. **Databricks Account**
- ✅ Databricks Account Console access
- ✅ Pre-created MWS objects:
  - `mws_credentials_id` - Cross-account IAM role credentials
  - `mws_storage_config_id` - Root storage bucket configuration
  - `mws_network_id` - VPC network configuration
  - `mws_private_access_settings_id` - Private access settings

### 3. **AWS Infrastructure**
- ✅ Existing VPC (`vpc_id`)
- ✅ Private subnets (`private_subnet_ids`) - at least 2
- ✅ Security groups (`security_group_ids`)

### 4. **Terraform**
- ✅ Terraform >= 1.6.0 installed
- ✅ AWS Provider >= 5.60
- ✅ Databricks Provider >= 1.51.0

### 5. **Terraform State Backend**
- ✅ S3 bucket for Terraform state (or create one)

---

## Step 1: Prepare Configuration

### 1.1 Copy Example Configuration

```bash
cd ub-tf-dbx-envs/terraform/stag
cp examples/stag/terraform.tfvars.example terraform.tfvars
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
mws_credentials_id             = "cred-stag-001"      # Your MWS credentials ID
mws_storage_config_id          = "storage-stag-001"    # Your MWS storage config ID
mws_network_id                 = "network-stag-001"   # Your MWS network ID
mws_private_access_settings_id = "pas-stag-001"       # Your MWS PAS ID
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
  product    = "damage-prevention"    # Match product_name above
  customer   = "urbint"               # Your customer name
  region     = "us-east-2"           # Match region above
  # ... other tags
}
```

#### Workspace Configuration
```hcl
workspace = {
  workspace_name = "dp-stag-ws-us-east-2"  # Format: {product}-{env}-ws-{region}
  pricing_tier   = "STANDARD"              # STANDARD, PREMIUM, or ENTERPRISE
  
  uc_metastore_name   = "dp-stag-metastore-us-east-2"  # Format: {product}-{env}-metastore-{region}
  uc_metastore_region = "us-east-2"                     # Match your region
  uc_external_prefix  = "s3://dp-shared-uc/"           # Your S3 prefix for UC
  uc_storage_role_arn = "arn:aws:iam::123456789012:role/uc-role"  # IAM role ARN for UC
  
  # Update cluster configurations
  clusters = {
    cl1 = {
      cluster_name  = "dp-stag-cluster-a"  # Your cluster name
      spark_version = "13.3.x-scala2.12"   # Spark version
      node_type_id  = "i3.xlarge"          # Instance type
      num_workers   = 2                    # Number of workers
    }
    # ... cl2, cl3
  }
  
  # Update catalog storage roots
  catalogs = {
    catalog1 = {
      storage_root = "s3://dp-shared-uc/stag/catalog1/"  # Your S3 path
      grants       = []                                   # Optional grants
    }
    # ... catalog2, catalog3
  }
}
```

#### Unity Catalog Variables
```hcl
aws_account_id        = "123456789012"        # Your AWS account ID
unity_metastore_owner = "admin@example.com"   # UC metastore owner email
prefix                = "dp"                  # Resource prefix
```

### 1.3 Update Backend Configuration

Edit `backend.tf`:

```hcl
terraform {
  backend "s3" {
    bucket         = "your-terraform-state-bucket"  # CHANGE: Your state bucket
    key            = "dbx-envs/staging/terraform.tfstate"
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

This pass creates the S3 bucket, Databricks workspace, and Unity Catalog metastore.

### 2.1 Initialize Terraform

```bash
cd ub-tf-dbx-envs/terraform/stag
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
- Unity Catalog metastore creation
- AWS Secrets Manager secret creation (for workspace credentials)

**Review the plan carefully** to ensure all resources are correct.

### 2.3 Apply Pass-1

```bash
terraform apply
```

Type `yes` when prompted, or use:
```bash
terraform apply -auto-approve
```

**This will take 5-15 minutes** (workspace creation is the longest step).

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
workspace_url = "https://dbc-abc12345-6789.cloud.databricks.com"
metastore_id = "abc123def456"
s3_bucket_name = "dp-damage-prevention-stag-us-east-2-s3"
```

**✅ What happened automatically:**
- Workspace URL and ID were automatically stored in AWS Secrets Manager
- Secret name: `damage-prevention-stag-us-east-2-databricks-workspace`
- No manual action needed for this step!

---

## Step 3: Create and Store PAT

**⚠️ IMPORTANT:** This is a manual step that must be completed before Pass-2.

### 3.1 Create PAT in Databricks Workspace

1. **Log into the workspace:**
   - Open the workspace URL from Pass-1 output
   - Example: `https://dbc-abc12345-6789.cloud.databricks.com`
   - Log in with your Databricks account credentials

2. **Navigate to Access Tokens:**
   - Click on your **user icon** (top right corner)
   - Select **User Settings**
   - Click on **Access Tokens** tab

3. **Generate new token:**
   - Click **Generate New Token**
   - Add a comment: `Terraform automation for staging`
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
  "stag" \
  "us-east-2"
```

**Expected output:**
```
Secret damage-prevention-stag-us-east-2-databricks-workspace already exists. Updating...
Secret updated successfully!

Secret Name: damage-prevention-stag-us-east-2-databricks-workspace
Workspace URL: https://dbc-abc12345-6789.cloud.databricks.com
PAT: [REDACTED]
```

#### Option B: Using AWS CLI

```bash
SECRET_NAME="damage-prevention-stag-us-east-2-databricks-workspace"
WORKSPACE_URL="https://dbc-abc12345-6789.cloud.databricks.com"
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
   - Find secret: `damage-prevention-stag-us-east-2-databricks-workspace`

2. **Retrieve current secret:**
   - Click on the secret name
   - Click **Retrieve secret value**
   - Click **Edit**

3. **Update the JSON:**
   ```json
   {
     "workspace_id": "1234567890123456",
     "workspace_url": "https://dbc-abc12345-6789.cloud.databricks.com",
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
  --secret-id "damage-prevention-stag-us-east-2-databricks-workspace" \
  --region us-east-2 \
  --query SecretString \
  --output text | jq -r '.workspace_pat'
```

**Expected:** Should return your PAT (not "MANUAL_UPDATE_REQUIRED")

---

## Step 4: PASS-2 - Deploy Compute & Data Resources

This pass creates the compute clusters and Unity Catalog catalogs.

### 4.1 Return to Terraform Directory

```bash
cd ub-tf-dbx-envs/terraform/stag
```

### 4.2 Review the Plan

```bash
terraform plan
```

**What to expect:**
- 3 compute clusters creation
- 3 Unity Catalog catalogs creation
- No changes to workspace or metastore (already created in Pass-1)

**Note:** Terraform will automatically retrieve workspace URL and PAT from Secrets Manager - no need to set them in terraform.tfvars!

### 4.3 Apply Pass-2

```bash
terraform apply
```

Type `yes` when prompted.

**This will take 2-5 minutes** (cluster creation is faster than workspace creation).

### 4.4 Verify Outputs

```bash
terraform output
```

**Expected outputs:**
```
s3_bucket_name = "dp-damage-prevention-stag-us-east-2-s3"
workspace_url = "https://dbc-abc12345-6789.cloud.databricks.com"
workspace_id = "1234567890123456"
metastore_id = "abc123def456"
cluster_ids = {
  "cl1" = "1234-567890-abc123"
  "cl2" = "1234-567890-def456"
  "cl3" = "1234-567890-ghi789"
}
catalog_names = {
  "catalog1" = "catalog1"
  "catalog2" = "catalog2"
  "catalog3" = "catalog3"
}
```

**✅ What happened automatically:**
- Workspace URL and PAT were automatically retrieved from Secrets Manager
- No manual provider.tf changes needed!
- All clusters and catalogs created successfully

---

## Step 5: Verify Deployment

### 5.1 Verify in Terraform

```bash
# View all outputs
terraform output

# Check specific resources
terraform output workspace_url
terraform output cluster_ids
terraform output catalog_names
```

### 5.2 Verify in Databricks Workspace

1. **Log into workspace:**
   - Use the workspace URL from outputs
   - Example: `https://dbc-abc12345-6789.cloud.databricks.com`

2. **Verify clusters:**
   - Go to **Compute** → **Clusters**
   - You should see 3 clusters:
     - `dp-stag-cluster-a`
     - `dp-stag-cluster-b`
     - `dp-stag-cluster-c`
   - All should be in **Running** state

3. **Verify catalogs:**
   - Go to **Data** → **Catalogs**
   - You should see 3 catalogs:
     - `catalog1`
     - `catalog2`
     - `catalog3`
   - **Note:** Catalogs are created without schemas (schemas must be created manually)

4. **Verify metastore:**
   - Go to **Settings** → **Unity Catalog**
   - Verify metastore `dp-stag-metastore-us-east-2` is assigned
   - Check metastore region and configuration

### 5.3 Verify in AWS

1. **S3 Bucket:**
   ```bash
   aws s3 ls | grep damage-prevention-stag
   ```
   Should show: `dp-damage-prevention-stag-us-east-2-s3`

2. **Secrets Manager:**
   ```bash
   aws secretsmanager describe-secret \
     --secret-id "damage-prevention-stag-us-east-2-databricks-workspace" \
     --region us-east-2
   ```
   Should show the secret exists and is accessible

---

## Troubleshooting

### Issue 1: Terraform Init Fails - Backend Bucket Not Found

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

### Issue 2: Pass-1 Fails - Invalid VPC/Subnet IDs

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

### Issue 3: Pass-1 Fails - MWS Object IDs Not Found

**Error:**
```
Error: ResourceDoesNotExistException: Credentials ID not found
```

**Solution:**
1. Verify MWS object IDs in Databricks Account Console:
   - Go to **Settings** → **Account Settings**
   - Check **Credentials**, **Storage**, **Networks**, **Private Access Settings**

2. Ensure objects are in the same Databricks account
3. Verify object IDs are correct (copy-paste to avoid typos)

---

### Issue 4: Pass-2 Fails - PAT Not Found

**Error:**
```
Error: authentication token not found
```

**Solution:**

1. **Verify PAT is stored in Secrets Manager:**
   ```bash
   aws secretsmanager get-secret-value \
     --secret-id "damage-prevention-stag-us-east-2-databricks-workspace" \
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

### Issue 5: Pass-2 Fails - Cannot Create Clusters

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
   - Verify Spark version is valid
   - Ensure num_workers is >= 1

---

### Issue 6: Pass-2 Fails - Cannot Create Catalogs

**Error:**
```
Error: cannot create catalog: metastore not found
```

**Solution:**
1. Verify metastore is assigned to workspace:
   - Log into workspace
   - Go to **Settings** → **Unity Catalog**
   - Verify metastore `dp-stag-metastore-us-east-2` is listed

2. Check S3 storage roots:
   - Verify S3 paths are accessible
   - Check IAM role has permissions for S3 paths
   - Ensure S3 bucket exists

3. Verify workspace has Unity Catalog enabled:
   - Check workspace pricing tier (STANDARD, PREMIUM, or ENTERPRISE)
   - Unity Catalog requires PREMIUM or ENTERPRISE

---

### Issue 7: Secrets Manager Access Denied

**Error:**
```
Error: AccessDeniedException: User is not authorized to perform: secretsmanager:GetSecretValue
```

**Solution:**
1. Verify IAM permissions:
   ```json
   {
     "Effect": "Allow",
     "Action": [
       "secretsmanager:GetSecretValue",
       "secretsmanager:DescribeSecret",
       "secretsmanager:CreateSecret",
       "secretsmanager:UpdateSecret"
     ],
     "Resource": "arn:aws:secretsmanager:*:*:secret:damage-prevention-*-databricks-workspace"
   }
   ```

2. Check AWS credentials:
   ```bash
   aws sts get-caller-identity
   ```

---

## Quick Reference

### Deployment Commands Summary

```bash
# Step 1: Prepare
cd ub-tf-dbx-envs/terraform/stag
cp examples/stag/terraform.tfvars.example terraform.tfvars
# Edit terraform.tfvars with your values

# Step 2: Pass-1
terraform init
terraform plan
terraform apply
WORKSPACE_URL=$(terraform output -raw workspace_url)

# Step 3: Create and Store PAT
# (Manual step - create PAT in workspace UI, then store using script/CLI/Console)

# Step 4: Pass-2
terraform plan
terraform apply

# Step 5: Verify
terraform output
```

### Secret Name Format

```
{product_name}-{environment}-{region}-databricks-workspace
```

**Example:**
```
damage-prevention-stag-us-east-2-databricks-workspace
```

### Helper Script Location

```
ub-tf-dbx-platform/store-workspace-credentials.sh
```

### Workspace Naming Convention

- Workspace: `{product}-{env}-ws-{region}`
- Metastore: `{product}-{env}-metastore-{region}`

**Example:**
- Workspace: `dp-stag-ws-us-east-2`
- Metastore: `dp-stag-metastore-us-east-2`

---

## What Gets Created

### Pass-1 Resources:
- ✅ S3 Bucket: `dp-damage-prevention-stag-us-east-2-s3`
- ✅ Databricks Workspace: `dp-stag-ws-us-east-2`
- ✅ Unity Catalog Metastore: `dp-stag-metastore-us-east-2`
- ✅ Secrets Manager Secret: `damage-prevention-stag-us-east-2-databricks-workspace`

### Pass-2 Resources:
- ✅ 3 Compute Clusters: `dp-stag-cluster-a`, `dp-stag-cluster-b`, `dp-stag-cluster-c`
- ✅ 3 Unity Catalog Catalogs: `catalog1`, `catalog2`, `catalog3` (no schemas)

---

## Next Steps

After successful deployment:

1. **Create Schemas:**
   - Log into workspace
   - Go to **Data** → **Catalogs**
   - Select a catalog → **Create Schema**
   - Schemas are not created automatically

2. **Configure Permissions:**
   - Set up catalog and schema permissions
   - Configure user/group access

3. **Start Using:**
   - Connect clusters to catalogs
   - Create tables and run queries
   - Begin data engineering workflows

---

## Cleanup

To destroy all resources:

```bash
terraform destroy
```

**⚠️ Warning:** This will delete:
- All clusters
- All catalogs
- Unity Catalog metastore
- Databricks workspace
- S3 bucket

**Note:** 
- MWS objects are NOT deleted (managed separately)
- Secrets Manager secret is NOT deleted (kept for reference)

---

## Additional Resources

- **Main README**: `../../README.md`
- **Repo B Documentation**: `../../../ub-tf-dbx-platform/README.md`
- **Example Configuration**: `terraform.tfvars.example`

---

**Last Updated**: 2024  
**Environment**: Staging  
**Terraform Version**: >= 1.6.0
