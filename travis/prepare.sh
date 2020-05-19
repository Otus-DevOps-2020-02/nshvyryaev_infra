#!/bin/bash
set -e

echo Prepare VM for running checks

echo Install Ansible
sudo pip install --upgrade pip
sudo pip install ansible
ansible --version

echo Install Terraform
mkdir tmp
pushd tmp
echo Install Terraform
wget https://releases.hashicorp.com/terraform/"$tf_version"/terraform_"$tf_version"_linux_amd64.zip
unzip terraform_"$tf_version"_linux_amd64.zip
sudo mv terraform /usr/local/bin/
terraform --version
rm terraform_"$tf_version"_linux_amd64.zip
popd

echo Install Tflint
curl https://raw.githubusercontent.com/terraform-linters/tflint/master/install_linux.sh | sudo bash

echo Install Ansible Lint
pip install ansible-lint
