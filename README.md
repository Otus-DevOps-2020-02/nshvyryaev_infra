# nshvyryaev_infra [![Build Status](https://travis-ci.com/Otus-DevOps-2020-02/nshvyryaev_infra.svg?branch=master)](https://travis-ci.com/Otus-DevOps-2020-02/nshvyryaev_infra)
nshvyryaev Infra repository

## HW3 Cloud bastion access
### Infrastructure
There are two instances:
bastion_IP = 35.189.220.151
someinternalhost_IP = 10.132.0.3

Only bastion has external IP.

### Connecting to the GCP hosts via SSH
Use bastion host to connect to an instance with internal IP only.

Connect in one command:
`ssh -i {identity_file} -A -t {user}@{bastion_external_IP} ssh {some_internal_host_IP}`

Connection command example:
`ssh -i ~/.ssh/otus/appuser -A -t appuser@35.189.220.151 ssh 10.132.0.3`

To use ssh alias `someinternalhost` add following config to your `~/.ssh/config`:
```text
Host someinternalhost
	ForwardAgent yes
	HostName 10.132.0.3
	User appuser
	IdentityFile ~/.ssh/otus/appuser
	ProxyCommand ssh -W %h:%p appuser@35.189.220.151
```

### VPN
VPN is based on Pritunl server. Configuration could be found at `cloud-bastion.ovpn`.

Pritunl web admin panel has valid TLS certificate
signed for `35-189-220-151.sslip.io` domain

## HW4 Cloud deploy
### Variables for testing
testapp_IP = 35.240.45.64
testapp_port = 9292
### Command to create instance with startup script
Execute from project root.
```bash
gcloud compute instances create reddit-app-auto\
  --boot-disk-size=10GB \
  --image-family ubuntu-1604-lts \
  --image-project=ubuntu-os-cloud \
  --machine-type=g1-small \
  --tags puma-server \
  --restart-on-failure \
  --metadata-from-file startup-script=startup_script.sh
```

### Command to create firewall rule
```bash
gcloud compute firewall-rules create default-puma-server \
    --direction=INGRESS \
    --priority=1000 \
    --network=default \
    --action=ALLOW \
    --rules=tcp:9292 \
    --source-ranges=0.0.0.0/0 \
    --target-tags=puma-server
```

## HW5 Packer base
### Creating images with packer
Run commands from directory `packer`. Use `variables.json.example` to create files with variables.
#### Base image without application
Create `variables.json` file with required parameters.
Run `packer build -var-file=variables.json ubuntu16.json`
#### Full image with application
Create `immutable_variables.json` file with required parameters.
Run `packer build -var-file=immutable_variables.json immutable.json`
#### Create an instance using image
Run `create-reddit-vm.sh` to create an instance from full image.
No more actions needed - server will operate as soon as an instance will be ready.

## HW6 Terraform 1
Terraform configuration is added to the project. See `terraform` directory for configuration details.
Use `terraform.tfvars.example` as an example of what can be configured via variables.
### Adding multiple SSH keys
#### Found issues
SSH keys are stored in single variable 'ssh-keys', that means that Terraform:
1. Removes manually added keys
2. You need to concatenate username into value separating key and user with colon
3. You need to concatenate multiple keys into single value and separate them with new line
### Load balancing
Added using Google module `https://github.com/terraform-google-modules/terraform-google-lb`.
Code was copied to add instances to targets pool without auto scaling.

Use `instance_count` variable to set desired count of instances in load balancer targets pool.


## HW7 Terraform 2
Terraform configuration is split into separate modules. Stage and prod environments created.
SSH IP limitation added to the project. External static IP added.
### Found issues
1. `SweetOps/storage-bucket/google` doesn't work with defaults. Specifying parameter "location" has fixed the issue.

### GCS backend
Terraform can use remote backend to store its state. This allows work together on the same project.
Running multiple apply command simultaneously is restricted, state is locked.

### Provisioning in modules
You should use absolute path in module in order to refer files located in module.
`${path.module}` will help.
Mongodb listens only on localhost by default. To allow external connections you need to add
DB host internal IP in `bindIp` config variable.

For some reason Travis build has failed... Let's check if it is caused by the code

## HW8 Ansible 1
Git module doesn't change anything if repo exists. Module makes change if we remove existing folder.

### JSON inventory
Static JSON inventory file has the same structure as YAML does. Dynamic has hosts configured as names only.
Each host variables are extracted into separate section `_meta: hostvars`. Dynamic JSON can't be used without a script.

## HW9 Ansible 2
* Playbook `reddit_app_one_play.yml` added for DB and APP configuration
* Playbook `reddit_app_multiple_plays.yml` added. Multiple plays simplify running a bit.
* Previous playbook is split into `app.yml, db.yml, deploy.yml`. Playbook `site.yml` launches them all.
* Dynamic inventory created using gcp_compute plugin
* Packer provisioning is reconfigured with Ansible.

To run Ansible deploy execute `ansible-playbook site.yml` from directory `ansible`.

Note: There was an issue with APT repo key provided in gist for packer_db.yml.

## HW10 Ansible 3
- Ansible roles added for app and db
- Both roles are used in playbook `site.yml`
- Two environments created: stage and prod
- Community role `jdauphant.nginx` used to configure http port proxy. 9292 firewall rule has been disabled, 80 port is enabled.
- Playbook users.yml added to create users on app host. Variables are encrypted with Ansible Vault. For SSH config see https://serverpilot.io/docs/how-to-enable-ssh-password-authentication/
- (*) Dynamic inventory from previous HW reused for both environments.
- (**) Travis build updated
  - validate packer templates
  - validate terraform configurations
  - lint Ansible playbooks
- Travis build result badge is added to the repo README.

## HW11 Ansible 4

### Vagrant
- Used for local VM creation using VirtualBox provider.
- Created VMs are provisioned with Ansible playbook `site.yml`
- Roles app and db are extended to install requirements prior to configuration.
- Packer templates are updated to use roles instead of playbooks
- (*) Nginx params are added to Vagrant file to enable application on port 80

### Molecule
- Molecule project created in `roles/db` via command `molecule init scenario -s default -r db -d vagrant`
- Test added to verify if DB is listening on default port

#### (*) Extra task
- Molecule project recreated in `roles/db` via command `molecule init scenario -s default -r db -d gce`
  - Molecule version must be below 3.0 to use drivers like vagrant, gce
- GCE integration added to travis
  - Service account has been created
  - Required parameters were encrypted in Travis configuration
  - Secrets like private key and GCP credentials were archived and encrypted
- Build badge is added to the `ansible-role-mongo` repo
- Slack notifications are configured for Travis builds for `ansible-role-mongo` repo

### How to use
- Run `ansible-galaxy install -r environments/stage/requirements.yml` to install required roles (including role `db`)
- Run `vagrant up` to create local virtual environment
  - Application should be available at http://10.10.10.20
  - Run `vagrant destroy` to remove virtual environment
- Use virtualenv:
  - Create with `virtualenv env`
  - Start using with `source env/bin/activate`
  - Stop using with `deactivate`
- Install dependencies with `pip install -r requirements.txt` inside virtualenv
- For Molecule test:
  - `molecule create` to create VMs
  - `molecule converge` to provision with Ansible
  - `molecule verify` to run tests
  - `molecule destroy` to clean up
