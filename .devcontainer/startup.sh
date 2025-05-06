ENVIRONMENT=${1:-"dev"}
FILE_secrets=".devcontainer/.env.${ENVIRONMENT}"

if [[ -n "${ARM_CLIENT_ID}" && -n "${ARM_CLIENT_SECRET}" && -n "${ARM_TENANT_ID}" && -n "${ARM_SUBSCRIPTION_ID}" ]]; then
    echo "Using pre-configured environment variables"
elif [[ -f "${FILE_secrets}" ]]; then
    echo "Loading secret environment variables from '${FILE_secrets}'"
    set -a
    source "${FILE_secrets}"
    set +a
else
    echo "No secrets file found for environment '${ENVIRONMENT}' "
    echo "Please set variables from .env.example file"
    exit 1
fi

if [[ -n "$ARM_CLIENT_ID" && -n "$ARM_CLIENT_SECRET" && -n "$ARM_TENANT_ID" ]]; then
    az login --service-principal -u $ARM_CLIENT_ID -p $ARM_CLIENT_SECRET --tenant $ARM_TENANT_ID
else
    echo "Missing required Azure credentials. Azure login skipped."
fi