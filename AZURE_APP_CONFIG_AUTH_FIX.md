# Azure App Configuration Authentication Fix

## Problem
GitHub Actions failing with Azure App Configuration connection error despite `APP_CONFIG_ENDPOINT` being correctly set:

```
ERROR:root:Unable to connect to Azure App Configuration. Please check APP_CONFIG_ENDPOINT setting. Failed to load configuration settings. No Azure App Configuration stores successfully loaded from.
WARNING:root:No Azure App Configuration connection string available, falling back to environment variables
```

## Root Cause Analysis

The issue is **authentication**, not the endpoint URL:

1. ✅ **Environment Variable Set**: `APP_CONFIG_ENDPOINT` is correctly configured
2. ❌ **Authentication Issue**: The Azure service principal credentials aren't properly accessible to the Python Azure SDK
3. ❌ **Permissions Issue**: The service principal may not have proper permissions on Azure App Configuration

## Solutions Implemented

### 1. Enhanced Authentication in GitHub Actions

#### PR Pipeline (`pr_pipeline.yaml`)
```yaml
# Added explicit credential passing to evaluation step
- name: Run evaluation
  env:
    AZURE_CLIENT_ID: ${{ fromJson(secrets.AZURE_CREDENTIALS).clientId }}
    AZURE_CLIENT_SECRET: ${{ fromJson(secrets.AZURE_CREDENTIALS).clientSecret }}
    AZURE_TENANT_ID: ${{ fromJson(secrets.AZURE_CREDENTIALS).tenantId }}
    APP_CONFIG_ENDPOINT: ${{ vars.APP_CONFIG_ENDPOINT }}
    allow_environment_variables: "true"
```

#### CI/CD Pipeline (`cicd_pipeline.yaml`)
```yaml
# Standardized credential format
env:
  AZURE_CLIENT_ID: ${{ fromJson(secrets.AZURE_CREDENTIALS).clientId }}
  AZURE_CLIENT_SECRET: ${{ fromJson(secrets.AZURE_CREDENTIALS).clientSecret }}
  AZURE_TENANT_ID: ${{ fromJson(secrets.AZURE_CREDENTIALS).tenantId }}
```

### 2. Added Authentication Verification

Both pipelines now include:
```bash
# Test Azure CLI authentication and App Config permissions
- name: Verify Azure authentication and App Config access
  run: |
    az account show
    CONFIG_NAME=$(echo "$APP_CONFIG_ENDPOINT" | sed 's|https://||' | sed 's|\.azconfig\.io||')
    az appconfig kv list --name "$CONFIG_NAME" --auth-mode login --top 1
```

### 3. Enhanced Error Handling and Fallback

The `AppConfigClient` now:
- ✅ Gracefully handles authentication failures
- ✅ Falls back to environment variables when App Config is unavailable
- ✅ Provides detailed debugging information
- ✅ Continues execution even if App Config fails

### 4. Improved Debugging

Enhanced evaluation scripts now show:
```python
print('Environment variables:')
for key in ['APP_CONFIG_ENDPOINT', 'AZURE_CLIENT_ID', 'AZURE_TENANT_ID']:
    print(f'  {key}: {os.environ.get(key, "NOT SET")}')
```

## Required Service Principal Permissions

The service principal needs these permissions on Azure App Configuration:

### 1. Azure RBAC Roles
- **App Configuration Data Reader** - To read configuration values
- **App Configuration Data Owner** - If writing configuration values (for CI/CD)

### 2. Key Vault Access (if using Key Vault references)
- **Key Vault Secrets User** - To read secrets referenced from App Configuration

### 3. Apply Permissions
```bash
# Get the service principal object ID
PRINCIPAL_ID=$(az ad sp show --id $AZURE_CLIENT_ID --query objectId -o tsv)

# Assign App Configuration Data Reader role
az role assignment create \
  --role "App Configuration Data Reader" \
  --assignee $PRINCIPAL_ID \
  --scope "/subscriptions/{subscription-id}/resourceGroups/{resource-group}/providers/Microsoft.AppConfiguration/configurationStores/{config-store-name}"
```

## Verification Steps

1. **Check GitHub Secrets**: Ensure `AZURE_CREDENTIALS` is properly formatted
2. **Check Environment Variables**: Verify `APP_CONFIG_ENDPOINT` is set
3. **Check Service Principal**: Verify it has proper permissions on App Configuration
4. **Test Authentication**: Use the verification step in the pipeline

## Expected Behavior After Fix

- ✅ **Success Path**: Azure App Configuration connects successfully
- ✅ **Graceful Fallback**: Falls back to environment variables if connection fails
- ✅ **No Hard Failures**: Pipeline continues even with App Config issues
- ✅ **Clear Debugging**: Detailed logs show exactly what's happening

## Testing Locally

To test the same authentication flow locally:
```bash
# Set the same environment variables
export AZURE_CLIENT_ID="your-client-id"
export AZURE_CLIENT_SECRET="your-client-secret"  
export AZURE_TENANT_ID="your-tenant-id"
export APP_CONFIG_ENDPOINT="https://appcs-3mgp3siciihde.azconfig.io"
export allow_environment_variables="true"

# Run the evaluation script
./evaluations/evaluate.sh --skip-eval
```
