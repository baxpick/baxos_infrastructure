# Certificate Migration Quick Reference

These are steps to move Azure login from client secret to certificate:

## Step 1: Generate Certificate

```bash
./scripts/generate_sp_certificate.sh azure-sp-prod 24 .certs
```

**Files created:**
- ✅ `.certs/azure-sp-prod.pem` (for Azure CLI & local dev)
- ✅ `.certs/azure-sp-prod.crt` (to upload to Azure)
- ✅ `.certs/azure-sp-prod.key` (private key, keep secret!)

---

## Step 2: Upload to Azure

Upload `.certs/azure-sp-prod.crt` to service principal certificates from Azure portal.

---

## Step 3: Update Local Environment

Edit `.devcontainer/.env.prod`:

```bash
ARM_CLIENT_ID=your-application-id
ARM_CLIENT_CERT_PATH=/workspaces/baxos_infrastructure/.certs/azure-sp-prod.pem
ARM_TENANT_ID=your-tenant-id
ARM_SUBSCRIPTION_ID=your-subscription-id
# Remove: ARM_CLIENT_SECRET=...
```

---

## Step 4: Prepare for GitHub Actions

```bash
# Generate base64-encoded certificate
cat .certs/azure-sp-prod.pem |base64 -w 0
```

**Add as GitHub Secret:**
- **Name:** `ARM_CLIENT_CERT_BASE64_<YOUR_ENVIRONMENT>`
- **Value:** `<paste base64 string>`
- **Location:** Repository → Settings → Secrets and variables → Actions → New secret

---

## Step 5: Test Locally

```bash
export FOLDER_bash=${FOLDER_ROOT}/bash
source .devcontainer/.env.prod
source bash/logging.sh
source bash/azure.sh

azure_login \
  --clientId ${ARM_CLIENT_ID} \
  --clientCertPath ${ARM_CLIENT_CERT_PATH} \
  --tenantId ${ARM_TENANT_ID}

az account show  # Should show your subscription
```
