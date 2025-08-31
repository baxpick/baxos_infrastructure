#!/usr/bin/env bash

# absolute path to root folder
if [[ "${FOLDER_ROOT}" == "" ]]; then
    echo "FOLDER_ROOT not set"
    exit 1
fi

# includes
# ########
export FOLDER_bash="${FOLDER_ROOT}/bash"
source "${FOLDER_bash}/logging.sh"
source "${FOLDER_bash}/azure.sh"

usage() {
    echo "Usage: $0"
    echo "  Make sure these environment variables are set:"
    echo "      GH_TOKEN_TO_SET_SECRETS : GitHub token to set secrets for actions"
    echo "      ACR_REGISTRY_NAME       : Full name of Azure Container Registry"
    echo "      REPO_FOR_ACR_SECRETS    : Repo where ACR secrets will be stored (e.g., baxpick/cpctelera_example)"
    exit 1
}

log_subtitle "ARGUMENTS (check & set)"
# ####################################

log_info "GH_TOKEN_TO_SET_SECRETS..."
[[ ! -z "${GH_TOKEN_TO_SET_SECRETS}" ]] || { log_error_no_exit "GH_TOKEN_TO_SET_SECRETS not set"; usage; }
log_info "GH_TOKEN_TO_SET_SECRETS='***'"

log_info "ACR_REGISTRY_NAME..."
[[ ! -z "${ACR_REGISTRY_NAME}" ]] || { log_error_no_exit "ACR_REGISTRY_NAME not set"; usage; }
log_info "ACR_REGISTRY_NAME='***'"

log_info "REPO_FOR_ACR_SECRETS..."
[[ ! -z "${REPO_FOR_ACR_SECRETS}" ]] || { log_error_no_exit "REPO_FOR_ACR_SECRETS not set"; usage; }
log_info "REPO_FOR_ACR_SECRETS='${REPO_FOR_ACR_SECRETS}'"

log_subtitle "SANITY"
# ###################

azure_login --clientId ${ARM_CLIENT_ID} --clientSecret ${ARM_CLIENT_SECRET} --tenantId ${ARM_TENANT_ID}

log_subtitle "Prepare variables"
# ##############################

log_info "ACR_REGISTRY_USER..."
ACR_REGISTRY_USER=$(az acr credential show --name "${ACR_REGISTRY_NAME}" --query username -o tsv 2>/dev/null)
[[ ! -z "${ACR_REGISTRY_USER}" ]] || { log_error_no_exit "ACR_REGISTRY_USER not found"; usage; }
log_info "ACR_REGISTRY_USER='***'"

log_info "ACR_REGISTRY_PASS..."
PASSWORDS=($(az acr credential show --name "${ACR_REGISTRY_NAME}" --query 'passwords[].value' -o tsv 2>/dev/null))
ACR_REGISTRY_PASS=${PASSWORDS[0]}
[[ ! -z "${ACR_REGISTRY_PASS}" ]] || { log_error_no_exit "ACR_REGISTRY_PASS not found"; usage; }
#ACR_REGISTRY_PASS2=${PASSWORDS[1]}
log_info "ACR_REGISTRY_PASS='***'"

log_subtitle "MAIN EXECUTION"
# ###########################

ensure_command gh

log_info "Github login..."
echo "${GH_TOKEN_TO_SET_SECRETS}" |run gh auth login --hostname github.com --with-token
run gh auth status
log_info "Github login is successfull"

log_info "Setting Github secrets..."
gh secret set ACR_USERNAME --repo "${REPO_FOR_ACR_SECRETS}" --body "${ACR_REGISTRY_USER}" && \
gh secret set ACR_PASSWORD --repo "${REPO_FOR_ACR_SECRETS}" --body "${ACR_REGISTRY_PASS}"
[[ $? -eq 0 ]] || { log_error "Setting Github secrets failed"; }
log_info "Setting Github secrets is successfull"

log_info "Triggering Docker build/push workflows"
run gh workflow run docker-build-push-cpc.yml --repo "${REPO_FOR_ACR_SECRETS}" --ref main
run gh workflow run docker-build-push-enterprise.yml --repo "${REPO_FOR_ACR_SECRETS}" --ref main
log_info "Docker build/push workflows triggered"
