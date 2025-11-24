# Production Environment - Databricks Infrastructure

This directory contains the Terraform configuration for deploying the **Production** Databricks environment using Repo B (`ub-tf-dbx-platform`).

## 📋 Table of Contents

1. [Overview](#overview)
2. [Architecture](#architecture)
3. [What Gets Created](#what-gets-created)
4. [Prerequisites](#prerequisites)
5. [Configuration](#configuration)
6. [Deployment Steps](#deployment-steps)
7. [Outputs](#outputs)
8. [Shared Metastore](#shared-metastore)
9. [Troubleshooting](#troubleshooting)

---

## Overview

The production environment creates a complete Databricks platform with:
- **1 Databricks Workspace** (`dp-prod-ws-us-east-2`)
- **1 Unity Catalog Metastore** (`dp-stag-metastore-us-east-2`) - **Shared from staging, assigned to production workspace**
- **3 Compute Clusters** (cl1, cl2, cl3)
- **3 Unity Catalog Catalogs** (prod_catalog1, prod_catalog2, prod_catalog3)
- **1 S3 Bucket** (for Databricks artifacts)

### Key Characteristics

- **Metastore**: Uses staging metastore (`dp-stag-metastore-us-east-2`) - **NOT created, only assigned**
- **Naming Convention**: All resources include region suffix (e.g., `dp-prod-ws-us-east-2`)
- **Secrets Manager**: Automatic credential storage/retrieval (no manual provider configuration needed)
- **2-Pass Deployment**: Realistic workflow matching Databricks requirements
- **Catalogs**: Created without schemas (schemas can be created manually after deployment)
- **⚠️ IMPORTANT**: Must deploy staging environment first to create the metastore

---

## Architecture

### High-Level Architecture Diagram

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                    PRODUCTION ENVIRONMENT                                   │
│                    (ub-tf-dbx-envs/terraform/prod)                          │
└─────────────────────────────────────────────────────────────────────────────┘
                                    │
                                    ▼
┌─────────────────────────────────────────────────────────────────────────────┐
│                    Repo C: Production Environment Module                    │
│                                                                             │
│  ┌─────────────────────────────────────────────────────────────────────┐  │
│  │  main.tf                                                             │  │
│  │  └─ module "dbx_platform" {                                         │  │
│  │       source = "git::.../ub-tf-dbx-platform.git"                    │  │
│  │       ...                                                            │  │
│  │     }                                                                │  │
│  └─────────────────────────────────────────────────────────────────────┘  │
└────────────────────────────────────┬──────────────────────────────────────┘
                                     │
                                     ▼
┌─────────────────────────────────────────────────────────────────────────────┐
│                    Repo B: ub-tf-dbx-platform                                │
│                    (Platform Orchestration Layer)                            │
│                                                                             │
│  ┌─────────────────────────────────────────────────────────────────────┐  │
│  │  Resources Created:                                                  │  │
│  │                                                                      │  │
│  │  1. S3 Bucket                                                        │  │
│  │     └─ dp-damage-prevention-prod-us-east-2-s3                        │  │
│  │                                                                      │  │
│  │  2. Databricks Workspace                                             │  │
│  │     └─ dp-prod-ws-us-east-2                                         │  │
│  │        ├─ VPC: vpc-xxx                                               │  │
│  │        ├─ Subnets: subnet-aaa, subnet-bbb                            │  │
│  │        └─ Security Groups: sg-xxx                                  │  │
│  │                                                                      │  │
│  │  3. Unity Catalog Metastore ⭐ ASSIGNED (from staging)              │  │
│  │     └─ dp-stag-metastore-us-east-2                                  │  │
│  │        └─ Assigned to: dp-prod-ws-us-east-2                         │  │
│  │                                                                      │  │
│  │  4. Compute Clusters (3 clusters)                                  │  │
│  │     ├─ dp-prod-cluster-a (i3.xlarge, 2 workers)                     │  │
│  │     ├─ dp-prod-cluster-b (i3.2xlarge, 3 workers)                    │  │
│  │     └─ dp-prod-cluster-c (m5.xlarge, 4 workers)                     │  │
│  │                                                                      │  │
│  │  5. Unity Catalog Catalogs (3 catalogs)                             │  │
│  │     ├─ prod_catalog1 → s3://damage-prevention-dashboard-prod-us-east-2/catalogs/prod/catalog1/  │  │
│  │     │   └─ Metastore: dp-stag-metastore-us-east-2 ⭐ SHARED        │  │
│  │     ├─ prod_catalog2 → s3://damage-prevention-dashboard-prod-us-east-2/catalogs/prod/catalog2/  │  │
│  │     │   └─ Metastore: dp-stag-metastore-us-east-2 ⭐ SHARED         │  │
│  │     └─ prod_catalog3 → s3://damage-prevention-dashboard-prod-us-east-2/catalogs/prod/catalog3/  │  │
│  │         └─ Metastore: dp-stag-metastore-us-east-2 ⭐ SHARED         │  │
│  │     Note: Catalogs created without schemas                          │  │
│  └─────────────────────────────────────────────────────────────────────┘  │
│                                                                             │
│  ┌─────────────────────────────────────────────────────────────────────┐  │
│  │  AWS Secrets Manager Integration                                     │  │
│  │  └─ Secret: dp-damage-prevention-prod-us-east-2-databricks-       │  │
│  │             workspace                                               │  │
│  │     ├─ workspace_id                                                 │  │
│  │     ├─ workspace_url                                                │  │
│  │     └─ workspace_pat (manually updated after PAT creation)          │  │
│  └─────────────────────────────────────────────────────────────────────┘  │
└────────────────────────────────────┬──────────────────────────────────────┘
                                     │
                                     ▼
┌─────────────────────────────────────────────────────────────────────────────┐
│                    Repo A: ub-tf-aws-databricks                            │
│                    (Reusable Module Library)                               │
│                                                                             │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐│
│  │   Workspace  │  │ Unity Catalog│  │   Cluster    │  │   Catalog    ││
│  │    Module    │  │    Module    │  │    Module    │  │    Module    ││
│  └──────────────┘  └──────────────┘  └──────────────┘  └──────────────┘│
└─────────────────────────────────────────────────────────────────────────────┘
```

### Resource Flow Diagram

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                          DEPLOYMENT FLOW                                    │
└─────────────────────────────────────────────────────────────────────────────┘

⚠️ STEP 0: Deploy Staging First (Required)
──────────────────────────────────────────
1. Deploy staging environment
2. Get staging metastore_id from outputs

                    ▼

PASS-1: Infrastructure Creation
────────────────────────────────
1. S3 Bucket Created
   └─ dp-damage-prevention-prod-us-east-2-s3

2. Databricks Workspace Created
   └─ dp-prod-ws-us-east-2
      ├─ Workspace ID: 1234567890123456
      └─ Workspace URL: https://dbc-xxx.cloud.databricks.com

3. Unity Catalog Metastore Assigned ⭐
   └─ dp-stag-metastore-us-east-2 (from staging)
      └─ Assigned to: dp-prod-ws-us-east-2

4. Secrets Manager Secret Created
   └─ Stores: workspace_id, workspace_url

                    ▼
         [Manual Step: Create PAT]
                    ▼

PASS-2: Compute & Data Resources
────────────────────────────────
5. 3 Compute Clusters Created
   ├─ dp-prod-cluster-a
   ├─ dp-prod-cluster-b
   └─ dp-prod-cluster-c

6. 3 Unity Catalog Catalogs Created
   ├─ prod_catalog1 (metastore: dp-stag-metastore-us-east-2) ⭐
   ├─ prod_catalog2 (metastore: dp-stag-metastore-us-east-2) ⭐
   └─ prod_catalog3 (metastore: dp-stag-metastore-us-east-2) ⭐
   Note: Catalogs created without schemas

7. Secrets Manager Updated
   └─ workspace_pat added
```

### Shared Metastore Configuration

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                    SHARED METASTORE ACCESS                                  │
└─────────────────────────────────────────────────────────────────────────────┘

                    ┌─────────────────────────┐
                    │  STAGING ENVIRONMENT    │
                    │                         │
                    │  Workspace:             │
                    │  dp-stag-ws-us-east-2   │
                    │                         │
                    │  Metastore: ⭐          │
                    │  dp-stag-metastore-     │
                    │  us-east-2             │
                    │  (CREATED)              │
                    │                         │
                    │  Catalogs:              │
                    │  catalog1, catalog2,     │
                    │  catalog3               │
                    └───────────┬─────────────┘
                                 │
                                 │ Shared Metastore
                                 ▼
                    ┌─────────────────────────┐
                    │ PRODUCTION ENVIRONMENT  │
                    │                         │
                    │  Workspace:             │
                    │  dp-prod-ws-us-east-2    │
                    │                         │
                    │  Metastore: ⭐          │
                    │  dp-stag-metastore-     │
                    │  us-east-2             │
                    │  (ASSIGNED)            │
                    │                         │
                    │  Catalogs:              │
                    │  prod_catalog1,         │
                    │  prod_catalog2,         │
                    │  prod_catalog3          │
                    └─────────────────────────┘
```

---

## What Gets Created

### 1. **S3 Bucket**
- **Name**: `dp-damage-prevention-prod-us-east-2-s3` (format: `{prefix}-{product_name}-{env}-{region}-s3`)
- **Purpose**: Databricks artifacts, logs
- **Features**: Versioning enabled, tagged with corporate tags

### 2. **Databricks Workspace**
- **Name**: `dp-prod-ws-us-east-2`
- **Pricing Tier**: PREMIUM (production typically uses premium/enterprise)
- **Network**: Connected to existing VPC with private subnets
- **MWS Configuration**: Uses pre-created MWS objects (credentials, storage, network, private access)

### 3. **Unity Catalog Metastore** ⭐
- **Name**: `dp-stag-metastore-us-east-2` (from staging)
- **Region**: `us-east-2`
- **Status**: **Assigned to production workspace** (created in staging)
- **Storage**: S3 bucket for external locations
- **IAM Role**: Configured for Unity Catalog access

### 4. **Compute Clusters** (3 clusters)

| Cluster | Name | Instance Type | Workers | Spark Version |
|---------|------|---------------|---------|--------------|
| cl1 | `dp-prod-cluster-a` | i3.xlarge | 2 | 13.3.x-scala2.12 |
| cl2 | `dp-prod-cluster-b` | i3.2xlarge | 3 | 13.3.x-scala2.12 |
| cl3 | `dp-prod-cluster-c` | m5.xlarge | 4 | 13.3.x-scala2.12 |

### 5. **Unity Catalog Catalogs** (3 catalogs)

| Catalog | Storage Root | Grants | Metastore |
|---------|--------------|--------|-----------|
| prod_catalog1 | `s3://damage-prevention-dashboard-prod-us-east-2/catalogs/prod/catalog1/` | None | `dp-stag-metastore-us-east-2` ⭐ |
| prod_catalog2 | `s3://damage-prevention-dashboard-prod-us-east-2/catalogs/prod/catalog2/` | data-engineers (USE_CATALOG) | `dp-stag-metastore-us-east-2` ⭐ |
| prod_catalog3 | `s3://damage-prevention-dashboard-prod-us-east-2/catalogs/prod/catalog3/` | data-engineers (USE_CATALOG) | `dp-stag-metastore-us-east-2` ⭐ |

**Note**: Catalogs are created without schemas. Schemas can be created manually in the Databricks workspace after deployment.

### 6. **AWS Secrets Manager Secret**
- **Name**: `dp-damage-prevention-prod-us-east-2-databricks-workspace`
- **Contents**:
  - `workspace_id`: Databricks workspace ID
  - `workspace_url`: Workspace URL
  - `workspace_pat`: Personal Access Token (updated after creation)

---

## Prerequisites

### 1. **Staging Environment Deployed** ⚠️ **REQUIRED**
- ✅ Staging environment must be deployed first
- ✅ Staging metastore must be created and accessible
- ✅ Get staging metastore ID from staging outputs:
  ```bash
  cd ../stag
  terraform output -raw metastore_id
  ```

### 2. **AWS Account**
- AWS CLI configured with appropriate credentials
- IAM permissions for:
  - EC2 (VPC, subnets, security groups)
  - S3 (bucket creation, Secrets Manager)
  - Databricks MWS API access

### 3. **Databricks Account**
- Databricks Account Console access
- Pre-created MWS objects:
  - `mws_credentials_id` - Cross-account IAM role credentials
  - `mws_storage_config_id` - Root storage bucket configuration
  - `mws_network_id` - VPC network configuration
  - `mws_private_access_settings_id` - Private access settings

### 4. **AWS Infrastructure**
- Existing VPC (`vpc_id`)
- Private subnets (`private_subnet_ids`) - at least 2
- Security groups (`security_group_ids`)

### 5. **Terraform**
- Terraform >= 1.6.0
- AWS Provider >= 5.60
- Databricks Provider >= 1.51.0

---

## Configuration

### Step 1: Copy Example Configuration

```bash
cd ub-tf-dbx-envs/terraform/prod
cp examples/prod/terraform.tfvars.example terraform.tfvars
```

### Step 2: Update `terraform.tfvars`

Edit `terraform.tfvars` and update the following values:

#### Identity
```hcl
product_name = "damage-prevention"  # Your product name
region       = "us-east-2"          # Your AWS region
# Note: service and environment are auto-computed (service="databricks", environment="prod")
```

#### Databricks Account / MWS
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
  "subnet-aaa111",  # Your private subnet IDs
  "subnet-bbb222",
]

security_group_ids = [
  "sg-0123abcd",  # Your security group IDs
]
```

#### Unity Catalog Configuration
```hcl
aws_account_id        = "123456789012"         # Your AWS account ID
unity_metastore_owner = "admin@example.com"   # UC metastore owner email
# Note: prefix is auto-computed from first 3 chars of product_name
```

#### Workspace Configuration
```hcl
workspace = {
  pricing_tier        = "PREMIUM"  # STANDARD, PREMIUM, or ENTERPRISE
  uc_storage_role_arn = "arn:aws:iam::123456789012:role/uc-role"  # IAM role ARN for UC
  
  # 3 Clusters
  clusters = {
    cl1 = {
      cluster_name  = "dp-prod-cluster-a"  # Cluster name
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
  
  # 3 Catalogs (unique names to avoid conflicts with staging/integration)
  catalogs = {
    prod_catalog1 = {
      grants = []  # Optional: grants list
    }
    prod_catalog2 = {
      grants = [
        {
          principal  = "data-engineers"  # Principal name
          privileges = ["USE_CATALOG"]
        }
      ]
    }
    prod_catalog3 = {
      grants = [
        {
          principal  = "data-engineers"
          privileges = ["USE_CATALOG"]
        }
      ]
    }
  }
}
# Note: The following are auto-computed:
# - workspace_name = "{product_name}-prod-ws-{region}"
# - uc_metastore_name = "{product_name}-stag-metastore-{region}" (references staging)
# - uc_metastore_region = {region}
# - uc_external_prefix = "s3://{product_name}-dashboard-prod-{region}/unity-catalog/"
# - catalog storage_root = "s3://{product_name}-dashboard-prod-{region}/catalogs/prod/{catalog_name}/"
```

#### Shared Metastore Configuration ⚠️
```hcl
# Get metastore_id from staging: cd ../stag && terraform output -raw metastore_id
shared_metastore_id = "abc12345-def6-7890-ghij-klmnopqrstuv"  # From staging outputs
# Note: create_metastore is hardcoded to false (uses staging metastore)
```

#### Tags
```hcl
tags = {
  owner    = "data-platform-team"  # Required: Resource owner
  customer = "urbint"               # Required: Customer name
}
# Note: The following tags are auto-computed:
# - env = "prod"
# - product = {product_name}
# - service = "databricks"
# - repo = "ub-tf-dbx-platform"
# - created_by = "terraform"
# - region = {region}
```

### Step 3: Update Backend Configuration

Edit `backend.tf`:

```hcl
terraform {
  backend "s3" {
    bucket         = "your-terraform-state-bucket"  # Your state bucket
    key            = "dbx-envs/production/terraform.tfstate"
    region         = "us-east-2"
    encrypt        = true
  }
}
```

---

## Deployment Steps

### Step 0: Deploy Staging First ⚠️

**IMPORTANT**: Production uses staging metastore. Deploy staging first:

```bash
cd ub-tf-dbx-envs/terraform/stag
terraform apply
```

Get staging metastore ID:
```bash
cd ub-tf-dbx-envs/terraform/stag
terraform output -raw metastore_id
```

Update production `terraform.tfvars` with the staging metastore ID.

### Pass-1: Infrastructure Creation

This pass creates the S3 bucket, Databricks workspace, and assigns the staging metastore.

```bash
# 1. Navigate to production directory
cd ub-tf-dbx-envs/terraform/prod

# 2. Initialize Terraform
terraform init

# 3. Review the plan
terraform plan

# 4. Apply (creates workspace + assigns metastore)
terraform apply
```

**Expected Output:**
```
workspace_id = "1234567890123456"
workspace_url = "https://dbc-xyz12345-6789.cloud.databricks.com"
metastore_id = "abc12345-def6-7890-ghij-klmnopqrstuv"  # Same as staging
s3_bucket_name = "dp-damage-prevention-prod-us-east-2-s3"
```

**After Pass-1:**
1. Note the `workspace_url` from outputs
2. Log into the workspace using the URL
3. Create a Personal Access Token (PAT) in the workspace UI
4. Add PAT to `terraform.tfvars` for Pass-2

### Pass-2: Compute & Data Resources

This pass creates the clusters and catalogs. **Terraform automatically stores the PAT in Secrets Manager.**

```bash
# 1. Add PAT to terraform.tfvars
# Edit terraform.tfvars and add:
workspace_pat = "dapi1234567890abcdef..."  # Your PAT from Step 3

# 2. Apply Pass-2 (creates clusters + catalogs)
# Terraform will automatically:
# - Store PAT in AWS Secrets Manager
# - Retrieve workspace_url and workspace_id from Secrets Manager
# - Create clusters and catalogs
terraform apply
```

**Expected Output:**
```
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

---

## Outputs

After deployment, view all outputs:

```bash
terraform output
```

### Key Outputs

| Output | Description | Example |
|--------|-------------|---------|
| `s3_bucket_name` | S3 bucket for Databricks | `dp-damage-prevention-prod-us-east-2-s3` |
| `workspace_url` | Databricks workspace URL | `https://dbc-xyz12345-6789.cloud.databricks.com` |
| `workspace_id` | Databricks workspace ID | `1234567890123456` |
| `metastore_id` | Unity Catalog metastore ID (shared from staging) | `abc12345-def6-7890-ghij-klmnopqrstuv` |
| `cluster_ids` | Map of cluster IDs | `{ "cl1" = "1234-567890-abc123", ... }` |
| `catalog_names` | Map of catalog names | `{ "prod_catalog1" = "prod_catalog1", ... }` |

---

## Shared Metastore

The production workspace accesses the metastore `dp-stag-metastore-us-east-2`, which is:
- **Created** in staging environment during Pass-1
- **Assigned** to the production workspace (`dp-prod-ws-us-east-2`)
- **Used by** all 3 catalogs in this workspace
- **Shared** with staging and integration workspaces (all environments use the same metastore)

### Metastore Details

- **Name**: `dp-stag-metastore-us-east-2`
- **Region**: `us-east-2`
- **Workspaces**: 
  - `dp-stag-ws-us-east-2` (staging)
  - `dp-intg-ws-us-east-2` (integration)
  - `dp-prod-ws-us-east-2` (production)
- **Status**: Created in staging, assigned to integration and production

### Catalog Naming

Since all environments share the same metastore, catalog names must be unique:
- **Staging catalogs**: `catalog1`, `catalog2`, `catalog3`
- **Integration catalogs**: `intg_catalog1`, `intg_catalog2`, `intg_catalog3`
- **Production catalogs**: `prod_catalog1`, `prod_catalog2`, `prod_catalog3`

You can view the metastore details in the Terraform outputs:

```bash
terraform output metastore_id
```

---

## Troubleshooting

### Common Issues

#### 1. **Metastore ID Not Found**
- **Issue**: `shared_metastore_id` is required but not provided
- **Solution**: 
  - Deploy staging environment first
  - Get metastore ID: `cd ../stag && terraform output -raw metastore_id`
  - Update production `terraform.tfvars` with the staging metastore ID

#### 2. **Terraform Init Fails**
- **Issue**: Backend S3 bucket doesn't exist
- **Solution**: Create the S3 bucket for Terraform state first

#### 3. **Workspace Creation Fails**
- **Issue**: Invalid VPC/subnet/security group IDs
- **Solution**: Verify VPC and subnet IDs exist and are in the correct region

#### 4. **MWS Object IDs Not Found**
- **Issue**: Invalid MWS credentials/storage/network IDs
- **Solution**: Verify MWS object IDs in Databricks Account Console

#### 5. **Pass-2 Fails - PAT Not Found**
- **Issue**: PAT not stored in Secrets Manager
- **Solution**: 
  - Create PAT in workspace UI
  - Add `workspace_pat` to `terraform.tfvars` and run `terraform apply` - Terraform automatically stores it in Secrets Manager

#### 6. **Catalog Creation Fails - Name Conflict**
- **Issue**: Catalog name already exists in metastore
- **Solution**: 
  - Use unique catalog names (prod_catalog1, prod_catalog2, prod_catalog3)
  - Verify staging/integration catalogs don't have the same names

#### 7. **Metastore Assignment Failed**
- **Issue**: Cannot assign metastore to workspace
- **Solution**: 
  - Verify staging metastore exists
  - Ensure staging metastore ID is correct in `terraform.tfvars`
  - Ensure production workspace is created first (Pass-1)

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

# Verify staging metastore ID
cd ../stag
terraform output metastore_id
```

---

## Additional Resources

- **Repo B Documentation**: `ub-tf-dbx-platform/README.md`
- **Repo A Documentation**: `ub-tf-aws-databricks/README.md`
- **Examples**: `examples/prod/terraform.tfvars.example`
- **Deployment Guide**: `examples/prod/EXAMPLE_DEPLOYMENT.md`
- **Staging Environment**: `../stag/README.md`
- **Integration Environment**: `../intg/README.md`

---

## Support

For issues or questions:
1. Check the troubleshooting section above
2. Review Repo B and Repo A documentation
3. Check Terraform state and logs
4. Contact the data platform team

---

**Last Updated**: 2024
**Terraform Version**: >= 1.6.0
**Environment**: Production
**⚠️ Remember**: Always deploy staging first!

