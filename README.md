This repository is designed to automate the process of building puppet-agent from the Puppetlabs puppet-agent repository.

## Requirements

 * ansible

## How To

The prerequisite to using this is that you have an EL7 machine that you can ssh into. With that assumption:

```
ssh <hostname>
yum install ansible -y
git clone https://github.com/ehelms/puppet-agent-build
cd puppet-agent-build
ansible-playbook build.yaml
```
