#!/usr/bin/env bash

set -e

cd lambda-resizer

sam build

cd ../infra

cd staging

terraform init

# check if terraform.tfvars exists
if [ ! -f terraform.tfvars ]; then
    echo "terraform.tfvars does not exist. Please create it in the directory infra/staging, Exiting..."
    exit 1
fi

terraform apply -auto-approve -input=false
