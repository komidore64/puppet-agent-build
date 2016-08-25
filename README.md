This repository is designed to automate the process of building puppet-agent from the Puppetlabs puppet-agent repository.

## Requirements

 * ansible

## How To

The prerequisite to using this is that you have an EL7 machine that you can ssh into. With that assumption:

```
yum install ansible -y
git clone https://github.com/ehelms/puppet-agent-build
cd puppet-agent-build
ansible-playbook -l <host> prep_env.yaml
ansible-playbook build.yaml
```

## Use Forklift for Vagrant

The Forklift repo can be used to spin up boxes with Vagrant as build targets.

```
yum install ansible -y
git clone https://github.com/ehelms/puppet-agent-build
cd puppet-agent-build
ansible-playbook -l <host> prep_env.yaml
ansible-playbook build.yaml
```
