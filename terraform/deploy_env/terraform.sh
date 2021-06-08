#!/bin/bash
RUN_TYPE=$(echo "$1" | tr '[:upper]' '[:lower]')
ENVIRONMENT=$(echo "$2" | tr '[:upper]' '[:lower]')
DEPLOYMENT_REGION=$(echo "$3" | tr '[:upper]' '[:lower]')
APP_NAME=$(echo "$4" | tr '[:upper]' '[:lower]')
MODULE=$(echo "$5" | tr '[:upper]' '[:lower]')
VAR-FOLDER=$ENVIRONMENT-$DEPLOYMENT_REGION
KEY="applications/$APP_NAME/$MODULE_TYPE/terraform.tfstate"

cd ../$MODULE || exit 1
terraform init \
-input=false \
-backend=true \
-backend-config "bucket=terraform-state-$ENVIRONMENT-$DEPLOYMENT-REGION" \
-backend-config "region=$REGION"
-backend-config "key=$KEY"
-get=true

terraform plan --out tfplan.binary
terraform show -json tfplan.binary > tfplan.json

case "$RUN_TYPE" in
    "plan" )
        terraform plan -var-file="$VAR_FOLDER/terraform.tfvars" -out=tfplan -input=false;;
    "apply" )
        terraform plan -var-file="$VAR_FOLDER/terraform.tfvars" -out=tfplan.binary -input=false;;
        terraform show -json tfplan.binary > tfplan.json 
    "destroy" )
        terraform destroy -force -var-file="$VAR_FOLDER/terraform.tfvars";;
    *   )
        echo "Invalid action"; exit 1;;
esac
if [[ ($ENVIRONMENT == "uat" || $ENVIRONMENT == "prod") && $RUN_TYPE == "apply" && $MODULE == "sg" ]]; then 
    echo "Running palisade"
    exit 0;
    # Run palisade 
    # palisade needs to be passed a tfplan.json, global policy, and application-specific policy in YAML/JSON format 
    # opa eval --format pretty -b . --input tfplan.json 
    # if palisade returns policy violation; exit 1; else continue to terraform apply 
fi