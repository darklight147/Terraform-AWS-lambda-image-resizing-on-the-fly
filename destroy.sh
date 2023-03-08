#!/usr/bin/env bash

set -e

echo "Destroying infrastructure..."

echo "Proceed at your own risk. This will delete all resources created by this project."

read -p "Are you sure you want to continue? (y/n) " -n 1 -r

echo

read -p "what is your AWS profile? " AWS_PROFILE

echo "AWS_PROFILE is now set to: $AWS_PROFILE"

if [[ $REPLY =~ ^[Yy]$ ]]
then
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

    S3_BUCKET=$(terraform output -raw target-bucket)

    echo "Deleting S3 bucket $S3_BUCKET"

    # proceed? (y/n)
    read -p "Are you sure you want to continue? (y/n) " -n 1 -r

    echo

    if [[ $REPLY =~ ^[Yy]$ ]]
    then
        aws s3 rm s3://$S3_BUCKET --recursive --profile $(test -z $AWS_PROFILE && echo "default" || echo $AWS_PROFILE)
        terraform destroy -input=false -auto-approve
    fi
    else
        echo "Exiting..."
        echo "Failed to destroy infrastructure"
        echo "Failed to delete S3 bucket $S3_BUCKET"
        exit 1
    fi


fi
