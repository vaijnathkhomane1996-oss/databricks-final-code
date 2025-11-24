# Pre-Deployment Checklist

Use this checklist to ensure you have all required information before deploying.

## ✅ Prerequisites Checklist

### 1. Terraform & AWS Setup
- [ ] Terraform >= 1.5.0 installed
- [ ] AWS CLI configured
- [ ] AWS credentials have permissions to create resources
- [ ] Access to target AWS region

### 2. Databricks Account Console Access
- [ ] Access to Databricks Account Console
- [ ] Permissions to create workspaces
- [ ] Permissions to create Unity Catalog metastores

### 3. MWS Objects (Pre-Created)
- [ ] **Credentials ID** - Cross-account IAM role
- [ ] **Storage Configuration ID** - S3 bucket config
- [ ] **Network ID** - VPC attachment config
- [ ] **Private Access Settings ID** - Private connectivity

**Where to find:** Databricks Account Console → Settings → Account Settings

### 4. AWS Resources
- [ ] Existing VPC ID
- [ ] At least 2 private subnets (different AZs)
- [ ] Security group IDs (with Databricks rules)
- [ ] S3 buckets for Unity Catalog (if using external locations)

### 5. Databricks Personal Access Token
- [ ] PAT created in Databricks
- [ ] PAT has cluster creation permissions
- [ ] PAT has Unity Catalog admin permissions
- [ ] PAT hasn't expired

**Where to create:** Databricks Workspace → User Settings → Access Tokens

---

## ✅ Required Variables Checklist

### Core Identity
- [ ] `product_name` - Your product/project name
- [ ] `service` - Service name (usually "databricks")
- [ ] `environment` - One of: intg, stag, prod, demo
- [ ] `region` - AWS region (e.g., "us-east-2")

### Databricks Account / MWS
- [ ] `databricks_account_id` - From Account Console
- [ ] `mws_credentials_id` - From Account Console
- [ ] `mws_storage_config_id` - From Account Console
- [ ] `mws_network_id` - From Account Console
- [ ] `mws_private_access_settings_id` - From Account Console

### Workspace Authentication
- [ ] `workspace_pat` - Databricks Personal Access Token

### Unity Catalog
- [ ] `aws_account_id` - Your 12-digit AWS account ID
- [ ] `unity_metastore_owner` - Email address or service principal
- [ ] `prefix` - Resource prefix (e.g., "dp", "prod")

### VPC Configuration
- [ ] `vpc_id` - Your existing VPC ID
- [ ] `private_subnet_ids` - List of at least 2 subnet IDs
- [ ] `security_group_ids` - List of security group IDs

### Tags (All Mandatory)
- [ ] `owner` - Team/owner name
- [ ] `env` - Must be: intg, stag, prod, demo
- [ ] `product` - Product name
- [ ] `service` - Service name
- [ ] `repo` - Repository name
- [ ] `created_by` - Creator (usually "terraform")
- [ ] `customer` - Customer name
- [ ] `region` - AWS region

### Workspace Configuration
- [ ] `workspace_name` - Workspace name
- [ ] `pricing_tier` - STANDARD, PREMIUM, or ENTERPRISE
- [ ] `uc_metastore_name` - Unity Catalog metastore name
- [ ] `uc_metastore_region` - Region for metastore
- [ ] `uc_external_prefix` - S3 prefix for external locations
- [ ] `uc_storage_role_arn` - IAM role ARN for Unity Catalog

### Clusters (At Least One)
For each cluster:
- [ ] `cluster_name` - Unique cluster name
- [ ] `spark_version` - Databricks runtime version
- [ ] `node_type_id` - AWS instance type
- [ ] `num_workers` - Number of worker nodes

### Catalogs (At Least One)
For each catalog:
- [ ] `storage_root` - S3 path (must end with `/`)
- [ ] `grants` - Optional list of grants

---

## ✅ Configuration Validation

### Before Running `terraform init`:
- [ ] All variables in `terraform.tfvars` are filled in
- [ ] No placeholder values (like "CHANGE") remain
- [ ] Module source URLs updated (if using Git sources)

### Before Running `terraform plan`:
- [ ] `terraform init` completed successfully
- [ ] All providers downloaded
- [ ] No module source errors

### Before Running `terraform apply`:
- [ ] `terraform plan` shows expected resources
- [ ] No errors in plan output
- [ ] Ready to wait 30-60 minutes for deployment

---

## ✅ Post-Deployment Verification

After successful deployment:
- [ ] Workspace URL is accessible
- [ ] Can log into Databricks workspace
- [ ] All clusters appear in Compute section
- [ ] All catalogs appear in Data → Catalogs
- [ ] Unity Catalog metastore is assigned
- [ ] S3 bucket is created

---

## 🚨 Common Issues to Avoid

1. **Missing MWS IDs** - Must be pre-created in Account Console
2. **Invalid PAT** - Must have correct permissions and not expired
3. **Wrong VPC/Subnets** - Must be private subnets in 2+ AZs
4. **Missing Tags** - All 8 tags are mandatory
5. **Invalid Node Type** - Check availability in your region
6. **Invalid Spark Version** - Use valid Databricks runtime version

---

**Once all items are checked, you're ready to deploy!** 🚀

