#!/usr/bin/env bash

set -e

cd lambda-resizer

sam build

cd ../infra

cd staging

terraform init

# check if variables.tfvars exists
if [ ! -f variables.tfvars ]; then
    echo "variables.tfvars does not exist. Please create it in the directory infra/staging, Exiting..."
    exit 1
fi

terraform apply -var-file=variables.tfvars
