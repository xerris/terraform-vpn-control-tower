#!/bin/bash
set -o nounset
set -o errexit


echo "###############################"
echo "## Starting Terraform script ##"
echo "###############################"
declare -A ACCOUNTS
ENV="${ENV:-dev}"
AWS_REGION="${AWS_REGION:-ca-central-1}"
PARENT_ID="${PARENT_ID:-r-xxxx}"
ACCOUNT_ID_IC="${ACCOUNT_ID_IC:-XXXXXXX}" #Interconnect account
DEPLOYMENT_ROLE="${DEPLOYMENT_ROLE:-project-deploy-role}"
PROFILE_IC="${PROFILE_IC:-project-role-ic}"
PROFILE_BASE="${PROFILE_BASE:-project-role-}"
SOURCE_PROFILE="${SOURCE_PROFILE:-projcet}"
BUCKET_NAME_IC="${BUCKET_NAME:-project-vpn-terraform-state}"
BUCKET_NAME_BASE="${BUCKET_NAME_BASE:-project-vpc-terraform-state}"
STATE_FILE_PATH="${STATE_FILE_PATH:-vpn-state.tfstate}"
ACCOUNTS="${ACCOUNTS:-( ["dev"]="XXXXXX" ["stage"]="XXXXXXX" ["prod"]="XXXXXX" )}"

OU_LIST=$(aws organizations list-organizational-units-for-parent --parent-id ${PARENT_ID} | jq '.OrganizationalUnits[].Arn' | jq -s .)
APPLY=${1:-0} #If set terraform will force apply changes

aws configure set role_arn "arn:aws:iam::${ACCOUNT_ID_IC}:role/${DEPLOYMENT_ROLE}" --profile $PROFILE_IC
aws configure set source_profile ${SOURCE_PROFILE} --profile $PROFILE_IC
aws configure set role_session_name test-session --profile $PROFILE_IC
export AWS_PROFILE=$PROFILE_IC
declare -A ACCOUNTS

ACTIONS=( "plan" "apply --auto approve" "destroy --auto-approve" )
terraform init \
-backend-config="bucket=${BUCKET_NAME}" \
-backend-config="key=${STATE_FILE_PATH}" \
-backend-config="region=${AWS_REGION}"

terraform validate
terraform plan --var="ou_list=${OU_LIST}"

echo "#####################################"
echo "## Executing terraform ${ACTIONS[$APPLY]} on IC ##"
echo "#####################################"
terraform ${ACTIONS[$APPLY]} --var="ou_list=${OU_LIST}"
if [ $? -eq 0 ]; then
    cd accounts
    for ENV_ELEMENT in "${!ACCOUNTS[@]}";do
        echo "############################################################################"
        echo "## Executing terraform ${ACTIONS[$APPLY]} on $ENV_ELEMENT ==> ${ACCOUNTS[$ENV_ELEMENT]} #"
        echo "############################################################################"
        aws configure set role_arn "arn:aws:iam::${ACCOUNTS[$ENV_ELEMENT]}:role/${DEPLOYMENT_ROLE}" --profile "${PROFILE_BASE}${ENV_ELEMENT}"
        aws configure set source_profile ${SOURCE_PROFILE} --profile "${PROFILE_BASE}${ENV_ELEMENT}"
        aws configure set role_session_name test-session --profile "${PROFILE_BASE}${ENV_ELEMENT}"
        export AWS_PROFILE="${PROFILE_BASE}${ENV_ELEMENT}"
        terraform init \
        -backend-config="bucket=${BUCKET_NAME_BASE}-${ENV_ELEMENT}" \
        -backend-config="key=${STATE_FILE_PATH}" \
        -backend-config="region=${AWS_REGION}"
        terraform apply --auto-approve --var="profile_ic=${PROFILE_IC}" --var="account_ic=${ACCOUNT_ID_IC}" -var-file=envs/${ENV_ELEMENT}.tfvars
        rm -rf .terraform*
    done
fi
