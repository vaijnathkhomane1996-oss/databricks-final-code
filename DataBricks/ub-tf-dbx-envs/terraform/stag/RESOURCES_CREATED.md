# Resources Created in Staging Environment

This document lists all AWS and Databricks resources that are created when deploying the staging environment using `ub-tf-dbx-envs/terraform/stag`.

---

## 📋 Overview

The staging environment creates:
- **1 S3 Bucket** (for Databricks artifacts and Unity Catalog storage)
- **1 Databricks Workspace** (with VPC integration)
- **1 Unity Catalog Metastore** (shared across all environments)
- **3 Databricks Clusters** (compute resources)
- **3 Unity Catalog Catalogs** (data containers)
- **1 AWS Secrets Manager Secret** (for storing workspace credentials)

**Total: 10 primary resources** (plus supporting resources created by underlying modules)

---

## 🔍 Detailed Resource List

### 1. **S3 Bucket**

**Resource Type:** `aws_s3_bucket`  
**Module:** `ub-tf-aws-s3` (from external repo)  
**Name Format:** `${product_name}-dashboard-${environment}-${region}`  
**Example:** `damage-prevention-dashboard-stag-us-east-2`

**Purpose:**
- Stores Databricks artifacts, logs, and Unity Catalog data
- Used as storage root for Unity Catalog metastore and catalogs

**Configuration:**
- Versioning: Enabled
- Tags: Applied with mandatory corporate tags

**Output:** `s3_bucket_name`

---

### 2. **Databricks Workspace**

**Resource Type:** `databricks_mws_workspaces` (via MWS API)  
**Module:** `workspace` (calls Repo A's workspace module)  
**Name:** From `workspace.workspace_name` variable  
**Example:** `dp-stag-ws-us-east-2`

**Purpose:**
- Main Databricks workspace for staging environment
- Provides compute and data platform capabilities

**Configuration:**
- Pricing Tier: `STANDARD`, `PREMIUM`, or `ENTERPRISE` (from `workspace.pricing_tier`)
- VPC Integration: Uses existing VPC, subnets, and security groups
- MWS Configuration: Uses provided MWS IDs (credentials, storage, network, private access settings)

**Outputs:**
- `workspace_id` - Workspace ID
- `workspace_url` - Workspace URL (e.g., `https://1234567890123456.cloud.databricks.com`)

**Note:** Workspace creation takes ~10-15 minutes.

---

### 3. **Unity Catalog Metastore**

**Resource Type:** `databricks_mws_metastores` (via MWS API)  
**Module:** `unitycatalog` (calls Repo A's unity-catalog module)  
**Name:** From `workspace.uc_metastore_name` variable  
**Example:** `dp-stag-metastore-us-east-2`

**Purpose:**
- Central metadata store for Unity Catalog
- **Shared across all environments** (staging, integration, production)
- Stores catalog, schema, and table metadata

**Configuration:**
- Region: From `workspace.uc_metastore_region`
- Storage Root: From `workspace.uc_external_prefix` (S3 bucket path)
- Storage Role: IAM role ARN from `workspace.uc_storage_role_arn`
- Owner: From `unity_metastore_owner` variable

**Output:** `metastore_id` - Used by integration and production environments

**Note:** 
- Uses existing shared metastore (`create_metastore = false`, `shared_metastore_id` provided)
- Integration and production reference this metastore (`create_metastore = false`)

---

### 4. **Databricks Clusters** (3 clusters)

**Resource Type:** `databricks_cluster`  
**Module:** `cluster` (calls Repo A's cluster module)  
**Created:** Only during Pass-2 (after workspace URL and PAT are available)

**Clusters Created:**
1. **cl1** - From `workspace.clusters.cl1`
   - Name: `dp-stag-cluster-a` (from `cluster_name`)
   - Spark Version: `13.3.x-scala2.12` (from `spark_version`)
   - Node Type: `i3.xlarge` (from `node_type_id`)
   - Workers: `2` (from `num_workers`)

2. **cl2** - From `workspace.clusters.cl2`
   - Name: `dp-stag-cluster-b`
   - Spark Version: `13.3.x-scala2.12`
   - Node Type: `i3.2xlarge`
   - Workers: `3`

3. **cl3** - From `workspace.clusters.cl3`
   - Name: `dp-stag-cluster-c`
   - Spark Version: `13.3.x-scala2.12`
   - Node Type: `m5.xlarge`
   - Workers: `4`

**Purpose:**
- Compute resources for running Spark jobs, notebooks, and SQL queries
- Each cluster can be used for different workloads

**Output:** `cluster_ids` - Map of cluster IDs keyed by cluster key (cl1, cl2, cl3)

**Note:** Clusters are created in Pass-2 after PAT is manually created and stored in Secrets Manager.

---

### 5. **Unity Catalog Catalogs** (3 catalogs)

**Resource Type:** `databricks_catalog` and `databricks_grants`  
**Module:** `catalog` (calls Repo A's catalog module)  
**Created:** Only during Pass-2 (after workspace URL and PAT are available)

**Catalogs Created:**
1. **catalog1** - From `workspace.catalogs.catalog1`
   - Name: `catalog1`
   - Storage Root: `s3://damage-prevention-dashboard-stag-us-east-2/catalogs/stag/catalog1/`
   - Grants: None (empty list)

2. **catalog2** - From `workspace.catalogs.catalog2`
   - Name: `catalog2`
   - Storage Root: `s3://damage-prevention-dashboard-stag-us-east-2/catalogs/stag/catalog2/`
   - Grants: `data-engineers` group with `USE_CATALOG` privilege

3. **catalog3** - From `workspace.catalogs.catalog3`
   - Name: `catalog3`
   - Storage Root: `s3://damage-prevention-dashboard-stag-us-east-2/catalogs/stag/catalog3/`
   - Grants: `data-engineers` group with `USE_CATALOG` privilege

**Purpose:**
- Data containers within Unity Catalog metastore
- Organize data into logical groups
- Each catalog has its own S3 storage root

**Output:** `catalog_names` - Map of catalog names keyed by catalog key

**Note:** 
- Catalogs are created in Pass-2 after metastore is assigned to workspace
- Schemas are NOT created automatically (must be created manually in Databricks UI)

---

### 6. **AWS Secrets Manager Secret**

**Resource Type:** `aws_secretsmanager_secret` and `aws_secretsmanager_secret_version`  
**Module:** Created directly in Repo B  
**Name Format:** `${product_name}-${environment}-${region}-databricks-workspace`  
**Example:** `damage-prevention-stag-us-east-2-databricks-workspace`

**Purpose:**
- Stores workspace URL and PAT automatically
- Enables automatic retrieval in Pass-2 without manual input
- Eliminates need to manually update `provider.tf`

**Contents:**
```json
{
  "workspace_id": "1234567890123456",
  "workspace_url": "https://1234567890123456.cloud.databricks.com",
  "workspace_pat": "dapi123...",
  "created_at": "2024-01-01T00:00:00Z",
  "updated_at": "2024-01-01T00:00:00Z"
}
```

**Configuration:**
- Created automatically after workspace is created
- PAT must be manually updated after creation (via Databricks UI or script)
- Secret version has `ignore_changes` lifecycle to prevent overwriting manual PAT updates

**Note:** Only created if `use_secrets_manager = true` (default).

---

## 📊 Resource Creation Timeline

### **Pass-1: Infrastructure Setup**

**Resources Created:**
1. ✅ S3 Bucket
2. ✅ Databricks Workspace
3. ✅ Unity Catalog Metastore (staging only)
4. ✅ AWS Secrets Manager Secret (with placeholder PAT)

**Duration:** ~15-20 minutes

**After Pass-1:**
- Workspace URL is available
- Workspace ID is available
- Metastore ID is available (for sharing with other environments)
- **Manual Step Required:** Create PAT token in Databricks UI and update Secrets Manager

---

### **Pass-2: Compute and Data Resources**

**Resources Created:**
1. ✅ 3 Databricks Clusters
2. ✅ 3 Unity Catalog Catalogs
3. ✅ Metastore Assignment (for integration/production, not staging)

**Duration:** ~5-10 minutes

**Prerequisites:**
- Workspace URL and PAT must be available (from Secrets Manager or override variables)
- Metastore must be assigned to workspace (for catalogs)

---

## 🔗 Resource Dependencies

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

**Key Dependencies:**
- Workspace must exist before Unity Catalog metastore
- Workspace must exist before clusters and catalogs
- Metastore must be assigned to workspace before catalogs
- PAT must be available before clusters and catalogs

---

## 📝 Outputs Available

After deployment, the following outputs are available:

| Output | Description | Example |
|--------|-------------|---------|
| `s3_bucket_name` | S3 bucket name | `damage-prevention-dashboard-stag-us-east-2` |
| `workspace_url` | Workspace URL | `https://1234567890123456.cloud.databricks.com` |
| `workspace_id` | Workspace ID | `1234567890123456` |
| `metastore_id` | Unity Catalog metastore ID | `abc12345-def6-7890-ghij-klmnopqrstuv` |
| `cluster_ids` | Map of cluster IDs | `{cl1 = "1234-567890-cluster1", cl2 = "...", cl3 = "..."}` |
| `catalog_names` | Map of catalog names | `{catalog1 = "catalog1", catalog2 = "catalog2", catalog3 = "catalog3"}` |

**To view outputs:**
```bash
cd ub-tf-dbx-envs/terraform/stag
terraform output
```

**To get specific output:**
```bash
terraform output -raw metastore_id
terraform output -json cluster_ids
```

---

## 🏷️ Tags Applied

All resources are tagged with mandatory corporate tags:

| Tag Key | Value | Example |
|---------|-------|---------|
| `owner` | Resource owner | `data-platform-team` |
| `env` | Environment | `stag` |
| `product` | Product name | `damage-prevention` |
| `service` | Service name | `databricks` |
| `repo` | Repository | `ub-tf-dbx-platform` |
| `created_by` | Creator | `terraform` |
| `customer` | Customer name | `urbint` |
| `region` | AWS region | `us-east-2` |

Additional tags are added for specific resources:
- Clusters: `component = "databricks-cluster"`, `cluster_name = "..."`
- Catalogs: `component = "databricks-catalog"`, `catalog_name = "..."`
- S3: `component = "storage"`, `purpose = "databricks-shared"`
- Secrets Manager: `component = "secrets-manager"`, `purpose = "databricks-workspace-credentials"`

---

## ⚠️ Important Notes

1. **Metastore Sharing:**
   - All environments (staging, integration, production) use the same existing shared metastore
   - Metastore ID must be retrieved from staging outputs before deploying integration/production

2. **2-Pass Deployment:**
   - Pass-1 creates infrastructure (S3, workspace, metastore)
   - Pass-2 creates compute and data resources (clusters, catalogs)
   - Manual PAT creation required between passes

3. **S3 Bucket Usage:**
   - All S3 paths use the bucket created during deployment
   - Format: `s3://${product_name}-dashboard-${environment}-${region}/...`
   - Unity Catalog prefix: `s3://.../unity-catalog/`
   - Catalog storage roots: `s3://.../catalogs/${environment}/catalogX/`

4. **No Schema Creation:**
   - Catalogs are created without schemas
   - Schemas must be created manually in Databricks UI after deployment

5. **Secrets Manager:**
   - Default behavior: credentials stored automatically
   - Can be disabled with `use_secrets_manager = false`
   - Can be overridden with `workspace_url_override` and `workspace_pat_override`

---

## 🔍 Verification

After deployment, verify resources:

**1. Check S3 Bucket:**
```bash
aws s3 ls s3://damage-prevention-dashboard-stag-us-east-2/
```

**2. Check Workspace:**
```bash
terraform output workspace_url
# Open URL in browser and verify workspace is accessible
```

**3. Check Metastore:**
```bash
terraform output metastore_id
# Verify in Databricks UI: Settings > Unity Catalog > Metastores
```

**4. Check Clusters:**
```bash
terraform output cluster_ids
# Verify in Databricks UI: Compute > Clusters
```

**5. Check Catalogs:**
```bash
terraform output catalog_names
# Verify in Databricks UI: Data > Catalogs
```

**6. Check Secrets Manager:**
```bash
aws secretsmanager get-secret-value \
  --secret-id damage-prevention-stag-us-east-2-databricks-workspace
```

---

**Last Updated:** 2024  
**Terraform Version:** >= 1.6.0

