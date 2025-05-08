#!/usr/bin/env bash

# Single entry point script

# absolute path to root folder
if [[ "${FOLDER_ROOT}" == "" ]]; then
    echo "FOLDER_ROOT not set"
    exit 1
fi

# includes
# ########
export FOLDER_bash="${FOLDER_ROOT}/bash"
source "${FOLDER_bash}/logging.sh"
source "${FOLDER_bash}/terraform.sh"

[[ "${LOG_VERBOSE}" == "YES" ]] || { log_warning "NOTE: for more detailed output, export LOG_VERBOSE=YES"; }

full_cmd=$(ps -o args= -p $$ | sed 's/^ *//')
log_box "$full_cmd"

usage() {
    echo "Usage: $0 -e ENVIRONMENT -a ACTION -p PROJECT_NAME"
    echo "  -e ENVIRONMENT   Environment (dev|prod)"
    echo "  -a ACTION        Action"
    echo "    resourcesCreate   : Create and initialize all resources if needed"
    echo "    resourcesDelete   : Delete all resources"
    echo "  -p PROJECT_NAME  Name of the project (e.g., baxos)"
    exit 1
}

# parse command line arguments
while getopts "e:a:p:h" opt; do
    case ${opt} in
        e )
            environment=$OPTARG
            ;;
        a )
            action=$OPTARG
            ;;
        p )
            projectName=$OPTARG
            ;;
        h )
            usage
            ;;
    esac
done

log_box "ARGUMENTS (check & set)"
# ###############################

log_info "environment..."
[[ ! -z "${environment}" ]] || environment=${ENVIRONMENT} # pass as: command line argument *or* environment var
[[ ! -z "${environment}" ]] || { log_error_no_exit "Environment not set"; usage; }
declare -a VALID_ENVIRONMENTS=(\
    "dev"\
    "prod"
)
[[ " ${VALID_ENVIRONMENTS[@]} " =~ " ${environment} " ]] || { log_error_no_exit "Invalid environment: '${environment}'"; usage; }
log_info "environment='${environment}'"

log_info "action..."
declare -a VALID_ACTIONS=(\
    "resourcesCreate"\
    "resourcesDelete"
)
[[ " ${VALID_ACTIONS[@]} " =~ " ${action} " ]] || { log_error_no_exit "Invalid action: '${action}'"; usage; }
log_info "action='${action}'"

log_info "projectName..."
[[ ! -z "${projectName}" ]] || { log_error_no_exit "Project name not set"; usage; }
# Basic validation: check if project folder exists
ensure_folder "${FOLDER_ROOT}/terraform/projects/${projectName}"
log_info "projectName='${projectName}'"

log_box "SANITY"
# ##############

azure_login ${ARM_CLIENT_ID} ${ARM_CLIENT_SECRET} ${ARM_TENANT_ID}

log_info "subscription..."
[[ ! -z "${ARM_SUBSCRIPTION_ID}" ]] || { log_error "Subscription id not set"; }
subscriptionId=$(az account show --query id --output tsv)
[[ "${subscriptionId}" == "${ARM_SUBSCRIPTION_ID}" ]] || { errorout "Logged to wrong subscription"; }
log_info "subscription=OK"

log_box "Prepare variables"
# #########################

TF_project_folder="${FOLDER_ROOT}/terraform/projects/${projectName}"

log_info "TF_file_variables..."
TF_file_variables="${TF_project_folder}/env/${environment}/terraform.tfvars"
ensure_file "${TF_file_variables}"
log_info "TF_file_variables=${TF_file_variables}"

log_info "TF_file_variables_backend..."
TF_file_variables_backend="${TF_project_folder}/env/${environment}/backend.tfvars"
ensure_file "${TF_file_variables_backend}"
log_info "TF_file_variables_backend=${TF_file_variables_backend}"

log_info "location..."
location=$(value_from ${TF_file_variables} location)
[[ ! -z "${location}" ]] || { log_error "Location not set"; }
log_info "location=${location}"

log_box "MAIN EXECUTION"
# ######################

declare -a TERRAFORM_ACTIONS=("resourcesCreate" "resourcesDelete")

# terraform related actions
if [[ " ${TERRAFORM_ACTIONS[@]} " =~ " ${action} " ]]; then

    terraform_backend_create \
        --location "${location}" \
        --fileVarsBackend "${TF_file_variables_backend}" \

    terraform_run \
        --folder "${TF_project_folder}" \
        --environment "${environment}" \
        --action "${action}" \
        --fileVarsBackend "${TF_file_variables_backend}" \
        --fileVars "${TF_file_variables}"

elif [[ "${action}" == "..." ]]; then
    echo "..."
else
    usage
fi
