#!/usr/bin/env bash

# When ACR is changed or created, credentials should be updated in:
#  - GitHub secrets (for workflows that push/pull images)
#  - Azure DevOps secret pipeline variables (for pipelines that push/pull images)

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
source "${FOLDER_bash}/azdo.sh"
source "${FOLDER_bash}/gh.sh"

usage() {
    echo "Usage: $0"
    echo "  Make sure these environment variables are set:"
    echo "      ACR_REGISTRY_NAME                   : Full name of Azure Container Registry"

    echo "      GH_TOKEN                            : GitHub token (for setting repo secrets, starting actions, ...)"
    echo "      GH_REPO                             : Repo where ACR pass will be stored, actions started, ... (e.g., baxpick/cpctelera_example)"

    echo "      AZDO_TOKEN                          : Azure DevOps token (for setting pipeline variables, starting pipelines, ...)"
    echo "      AZDO_PIPELINE_ORGANIZATION          : Azure DevOps pipeline for setting pipeline variables, starting, ... (organization)"
    echo "      AZDO_PIPELINE_PROJECT               : Azure DevOps pipeline for setting pipeline variables, starting, ... (project)"
    echo "      AZDO_PIPELINE_NAME                  : Azure DevOps pipeline for setting pipeline variables, starting, ... (name)"
    exit 1
}

log_subtitle "ARGUMENTS (check & set)"
# ####################################

log_info "ACR_REGISTRY_NAME..."
[[ ! -z "${ACR_REGISTRY_NAME}" ]] || { log_error_no_exit "ACR_REGISTRY_NAME not set"; usage; }
log_info "ACR_REGISTRY_NAME='***'"

log_info "GH_TOKEN..."
[[ ! -z "${GH_TOKEN}" ]] || { log_error_no_exit "GH_TOKEN not set"; usage; }
log_info "GH_TOKEN='***'"

log_info "GH_REPO..."
[[ ! -z "${GH_REPO}" ]] || { log_error_no_exit "GH_REPO not set"; usage; }
log_info "GH_REPO='${GH_REPO}'"

log_info "AZDO_TOKEN..."
[[ ! -z "${AZDO_TOKEN}" ]] || { log_error_no_exit "AZDO_TOKEN not set"; usage; }
log_info "AZDO_TOKEN='***'"

log_info "AZDO_PIPELINE_ORGANIZATION..."
[[ ! -z "${AZDO_PIPELINE_ORGANIZATION}" ]] || { log_error_no_exit "AZDO_PIPELINE_ORGANIZATION not set"; usage; }
log_info "AZDO_PIPELINE_ORGANIZATION='***'"

log_info "AZDO_PIPELINE_PROJECT..."
[[ ! -z "${AZDO_PIPELINE_PROJECT}" ]] || { log_error_no_exit "AZDO_PIPELINE_PROJECT not set"; usage; }
log_info "AZDO_PIPELINE_PROJECT='***'"

log_info "AZDO_PIPELINE_NAME..."
[[ ! -z "${AZDO_PIPELINE_NAME}" ]] || { log_error_no_exit "AZDO_PIPELINE_NAME not set"; usage; }
log_info "AZDO_PIPELINE_NAME='***'"

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

gh_login --pat "${GH_TOKEN}"

# GitHub : set secret repo variables
gh_repo_set_var --name ACR_USERNAME --value "${ACR_REGISTRY_USER}" --repo "${GH_REPO}"
gh_repo_set_var --name ACR_PASSWORD --value "${ACR_REGISTRY_PASS}" --repo "${GH_REPO}"

# GitHub : trigger workflows
run gh workflow run docker-build-push-cpc.yml --repo "${GH_REPO}" --ref main
run gh workflow run docker-build-push-enterprise.yml --repo "${GH_REPO}" --ref main

# Azure DevOps : set secret pipeline variables
export AZURE_DEVOPS_EXT_PAT="${AZDO_TOKEN}"
azdo_login --pat "${AZDO_TOKEN}" --organization "${AZDO_PIPELINE_ORGANIZATION}" --project "${AZDO_PIPELINE_PROJECT}"
PIPELINE_ID=$(az pipelines show --name "${AZDO_PIPELINE_NAME}" --query id -o tsv)
[[ -n "${PIPELINE_ID}" ]] || { log_error "Could not resolve pipeline ID"; exit 1; }
azdo_pipeline_set_var --name "vPip_ACR_USER" --value "${ACR_REGISTRY_USER}" --pipeline-id "${PIPELINE_ID}"
azdo_pipeline_set_var --name "vPip_ACR_PASSWORD" --value "${ACR_REGISTRY_PASS}" --pipeline-id "${PIPELINE_ID}"
