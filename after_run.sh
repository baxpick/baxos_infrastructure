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

# variables
TERRAFORM_DIR="${FOLDER_ROOT}/terraform/projects/baxos"

# MAIN
######

# When ACR is created or updated
log_title "ACR created or updated?"

log_info "IAAC_JSON_PLAN_FILE..."
IAAC_JSON_PLAN_FILE=$(find . -name "${environment}.plan.json")
ensure_file "${IAAC_JSON_PLAN_FILE}"
log_info "IAAC_JSON_PLAN_FILE='${IAAC_JSON_PLAN_FILE}'"
ensure_command jq
if jq -e '
  .resource_changes[]
  | select(.address == "azurerm_container_registry.acr")
  | (.change.actions[] | select(. == "create" or . == "update"))
' "${IAAC_JSON_PLAN_FILE}" >/dev/null; then
  SCRIPT="${FOLDER_ROOT}/after_run_when_acr_changed.sh"
  log_info "ACR was created or updated, run: ${SCRIPT}"

  "${SCRIPT}"
else
  log_info "ACR not created or updated, skipping..."
fi

# Upload website files (always)
log_title "Upload website files"

if  [ -n "${BAXOS_FILE_SHARE_SANAME}" ] && \
    [ -n "${BAXOS_FILE_SHARE_NAME}" ] && \
    [ -n "${BAXOS_FILE_SHARE_RG}" ] && \
    [ -n "${BAXOS_FILE_SHARE_FOLDER}" ]; then

    cd "${TERRAFORM_DIR}"

    KEY=$(az storage account keys list \
        --account-name "${BAXOS_FILE_SHARE_SANAME}" \
        --resource-group "${BAXOS_FILE_SHARE_RG}" \
        --query "[0].value" \
        --output tsv)

    [[ -n "$KEY" ]] || { log_error "Failed to get storage account key"; }

    az storage file upload-batch \
        --account-name "${BAXOS_FILE_SHARE_SANAME}" \
        --account-key "${KEY}" \
        --destination "${BAXOS_FILE_SHARE_NAME}" \
        --source "files/website" \
        --pattern "*" \
        --no-progress >/dev/null 2>&1

    cd - > /dev/null

    log_info "Website files uploaded"

else
    log_info "Storage account variables not set, skipping..."
fi