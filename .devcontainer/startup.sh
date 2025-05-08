ENVIRONMENT=${1:-"dev"}
FILE_secrets=".devcontainer/.env.${ENVIRONMENT}"

if  [ -n "${ARM_CLIENT_ID}" ] && \
    [ -n "${ARM_CLIENT_SECRET}" ] && \
    [ -n "${ARM_TENANT_ID}" ] && \
    [ -n "${ARM_SUBSCRIPTION_ID}" ]; then

    echo "Using pre-configured environment variables"

elif [ -f "${FILE_secrets}" ]; then

    echo "Loading secrets from ${FILE_secrets}..."

    cp "${FILE_secrets}" ~/.devcontainer_env
    # REMARK: set -a and set +a are used to export all variables in the file so that subshells can access them
    grep -q "devcontainer_env" ~/.bashrc || echo 'if [ -f ~/.devcontainer_env ]; then set -a; source ~/.devcontainer_env; set +a; fi' >> ~/.bashrc
    . ~/.devcontainer_env
else
    echo "No secrets file found for environment: ${ENVIRONMENT}"
    
    exit 1
fi

if  [ -n "${ARM_CLIENT_ID}" ] && \
    [ -n "${ARM_CLIENT_SECRET}" ] && \
    [ -n "${ARM_TENANT_ID}" ] && \
    [ -n "${ARM_SUBSCRIPTION_ID}" ]; then
    
    az login --service-principal -u ${ARM_CLIENT_ID} -p ${ARM_CLIENT_SECRET} --tenant ${ARM_TENANT_ID}
else
    echo "Missing required Azure credentials. Azure login skipped."
fi
