ENVIRONMENT=${1:-"dev"}
FILE_secrets=".devcontainer/.env.${ENVIRONMENT}"

# Upgrades
# ########

az upgrade --yes

# Load secrets
# ############

if [ -f "${FILE_secrets}" ]; then

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
    [ -n "${ARM_CLIENT_CERT_PATH}" ] && \
    [ -n "${ARM_TENANT_ID}" ] && \
    [ -n "${ARM_SUBSCRIPTION_ID}" ]; then
    
    if command -v az >/dev/null; then
        if az login --service-principal \
                    --username ${ARM_CLIENT_ID} \
                    --certificate ${ARM_CLIENT_CERT_PATH} \
                    --tenant ${ARM_TENANT_ID} >/dev/null 2>&1 ; then
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

# MOUNT AZURE FILE SHARE
# ######################

if  [ -n "${BAXOS_FILE_SHARE_SANAME}" ] && \
    [ -n "${BAXOS_FILE_SHARE_NAME}" ] && \
    [ -n "${BAXOS_FILE_SHARE_RG}" ] && \
    [ -n "${BAXOS_FILE_SHARE_FOLDER}" ]; then
        
    echo "[MOUNT AZURE FILE SHARE] 🔐 Getting storage account key..."
    BAXOS_FILE_SHARE_SA_KEY=$(az storage account keys list \
    --account-name "${BAXOS_FILE_SHARE_SANAME}" \
    --resource-group "${BAXOS_FILE_SHARE_RG}" \
    --query "[0].value" \
    --output tsv)
    [ -n "${BAXOS_FILE_SHARE_SA_KEY}" ] || { echo "❌ Failed to get storage key"; exit 1; }

    echo "[MOUNT AZURE FILE SHARE] 📁 Creating mount point at ${BAXOS_FILE_SHARE_FOLDER}..."
    mkdir -p "${BAXOS_FILE_SHARE_FOLDER}" || true

    echo "[MOUNT AZURE FILE SHARE] 🔗 Mounting Azure File Share..."
    mount -t cifs \
        "//${BAXOS_FILE_SHARE_SANAME}.file.core.windows.net/${BAXOS_FILE_SHARE_NAME}" \
        "${BAXOS_FILE_SHARE_FOLDER}" \
        -o "username=${BAXOS_FILE_SHARE_SANAME},password=${BAXOS_FILE_SHARE_SA_KEY},dir_mode=0777,file_mode=0777,vers=3.0,noperm,mfsymlinks,serverino,nosharesock,actimeo=30,cache=strict"
    [ $? -eq 0 ] || { echo "❌ Failed to mount Azure File Share"; exit 1; }
else
    echo "[MOUNT AZURE FILE SHARE] Missing required variables. Mounting skipped."
fi
