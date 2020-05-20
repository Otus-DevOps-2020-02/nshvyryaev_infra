#!/bin/bash
set -ex

DIR=$(pwd)

echo -----------------------------------------------------------------------------
echo Packer templates validation
packer validate -var-file=packer/variables.json.example packer/ubuntu16.json
packer validate -var-file=packer/variables.json.example packer/immutable.json
packer validate -var-file=packer/variables.json.example packer/app.json
packer validate -var-file=packer/variables.json.example packer/db.json

echo -----------------------------------------------------------------------------
echo Terraform validate & tflint
for ENV_NAME in stage prod
do
    echo Terraform validate ${ENV_NAME}
    pushd terraform/${ENV_NAME}
        mv backend.tf backend.tf.bak
        cp terraform.tfvars.example terraform.tfvars
        terraform init
        terraform validate
        tflint
        rm terraform.tfvars
        mv backend.tf.bak backend.tf
    popd
done

echo -----------------------------------------------------------------------------
echo Ansible lint
cd $DIR && ansible-lint ansible/playbooks/*.yml --exclude roles/jdauphant.nginx -v

echo -----------------------------------------------------------------------------
