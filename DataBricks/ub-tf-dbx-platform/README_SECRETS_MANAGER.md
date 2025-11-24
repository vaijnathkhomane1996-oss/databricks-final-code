# Secrets Manager Integration - Quick Start Guide

## ✅ Repo B is Now Configured for Secrets Manager (Default)

Repo B (`ub-tf-dbx-platform`) is now configured to automatically use AWS Secrets Manager for storing and retrieving workspace URL and PAT.

---

## 🚀 How to Use

### Step 1: First Deployment (Pass-1)

Deploy workspace first:

```bash
cd terraform/<env>
terraform apply -target=module.workspace
```

### Step 2: Get Workspace URL

```bash
WORKSPACE_URL=$(terraform output -raw workspace_url)
echo "Workspace URL: $WORKSPACE_URL"
```

### Step 3: Create PAT in Databricks UI

1. Log into workspace using the URL from Step 2
2. Go to **User Settings** → **Access Tokens**
3. Generate new token
4. Copy the token

### Step 4: Store PAT in Terraform (Automatic - No Script Needed!)

**✅ NEW: No script needed! Just provide PAT in `terraform.tfvars`**

Add the PAT to your `terraform.tfvars` file:

```hcl
# In terraform.tfvars (Pass-2)
workspace_pat = "dapi1234567890abcdef..."  # Your PAT from Step 3
```

### Step 5: Continue Deployment (Pass-2)

**Terraform will automatically:**
- ✅ Store the PAT in AWS Secrets Manager
- ✅ Retrieve workspace URL from Secrets Manager
- ✅ Use both for cluster and catalog creation

```bash
# Deploy everything - Terraform automatically handles Secrets Manager
terraform apply
```

**That's it! No manual script needed. Terraform handles everything automatically.**

---

## 📝 Configuration

### Default Behavior (Secrets Manager Enabled)

In `terraform.tfvars`, you can omit or leave empty:

```hcl
# These are optional - will be retrieved from Secrets Manager
# workspace_pat = ""  # Optional
use_secrets_manager = true  # Default
```

### Override if Needed

```hcl
# Override Secrets Manager values
workspace_url_override = "https://custom-url.cloud.databricks.com"
workspace_pat_override = "dapi..."
```

### Disable Secrets Manager

```hcl
use_secrets_manager = false
workspace_pat = "dapi..."  # Must provide manually
```

---

## 🔧 Secret Name Format

```
{product_name}-{environment}-{region}-databricks-workspace
```

Example: `damage-prevention-intg-us-east-2-databricks-workspace`

---

## 🔄 Update PAT When It Expires

**✅ NEW: Just update `terraform.tfvars` and run `terraform apply`**

```hcl
# In terraform.tfvars
workspace_pat = "NEW_PAT_TOKEN"  # Updated PAT
```

```bash
terraform apply  # Terraform automatically updates Secrets Manager
```

**No script needed! Terraform handles the update automatically.**

---

## ✅ Benefits

- ✅ No manual input required
- ✅ Secure storage in AWS Secrets Manager
- ✅ Easy PAT updates without code changes
- ✅ Version control safe (no secrets in code)
- ✅ Works across all environments

---

## 📚 Full Documentation

See `AUTOMATIC_CREDENTIALS_STORAGE.md` for complete documentation.

