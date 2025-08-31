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
  exit 0
fi
  