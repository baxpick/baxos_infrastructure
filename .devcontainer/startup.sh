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
    grep -q "devcontainer_env" ~/.bashrc || echo 'if [ -f ~/.devcontainer_env ]; then source ~/.devcontainer_env; fi' >> ~/.bashrc
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
