ENVIRONMENT=${1:-"dev"}
FILE_secrets=".devcontainer/.env.${ENVIRONMENT}"

# Load secrets
# ############

if  [ -n "${ARM_CLIENT_ID}" ] && \
    [ -n "${ARM_CLIENT_SECRET}" ] && \
    [ -n "${ARM_TENANT_ID}" ] && \
    [ -n "${ARM_SUBSCRIPTION_ID}" ] && \
    \
    [ -n "${AWS_ACCESS_KEY_ID}" ] && \
    [ -n "${AWS_SECRET_ACCESS_KEY}" ] && \
    [ -n "${AWS_DEFAULT_REGION}" ]; then 

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

# AZURE LOGIN
# ###########

if  [ -n "${ARM_CLIENT_ID}" ] && \
    [ -n "${ARM_CLIENT_SECRET}" ] && \
    [ -n "${ARM_TENANT_ID}" ] && \
    [ -n "${ARM_SUBSCRIPTION_ID}" ]; then
    
    if command -v az >/dev/null; then
        if az login --service-principal -u ${ARM_CLIENT_ID} -p ${ARM_CLIENT_SECRET} --tenant ${ARM_TENANT_ID}; then
            echo "[AZURE LOGIN] Azure CLI login successful."
        else
            echo "[AZURE LOGIN] Azure CLI login failed."
        fi
    else
        echo "[AZURE LOGIN] Azure CLI not found."
    fi
else
    echo "[AZURE LOGIN] Missing required credentials. Login skipped."
fi

# AWS LOGIN
# #########

if  [ -n "${AWS_ACCESS_KEY_ID}" ] && \
    [ -n "${AWS_SECRET_ACCESS_KEY}" ] && \
    [ -n "${AWS_DEFAULT_REGION}" ]; then
    
    if command -v aws >/dev/null; then
        if \
            aws configure set aws_access_key_id $AWS_ACCESS_KEY_ID && \
            aws configure set aws_secret_access_key $AWS_SECRET_ACCESS_KEY && \
            aws configure set default.region $AWS_DEFAULT_REGION; then
            
            echo "[AWS LOGIN] AWS CLI login successful."
        else
            echo "[AWS LOGIN] AWS CLI login failed."
        fi
    else
        echo "[AWS LOGIN] AWS CLI not found."
    fi
else
    echo "[AWS LOGIN] Missing required credentials. Login skipped."
fi
