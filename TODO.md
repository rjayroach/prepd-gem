# TODO

## Laptop provisioning

- Finish extras, virtualbox and vagrant TODOs in ansible-roles

In prepd:
- create a bootstrap.sh script that installs Ansible and dependencies, e.g. Homebrew, python, etc
- add a playbook that provisions a mac or ubuntu laptop with android, packer, extras, etc

- update README to document provisioning a mac (and ubuntu) from brand new:
1. git clone prepd
2. run bootstrap.sh
3. run ./laptop.yml
4. bin/console to create a client and project OR git clone a project created with prepd
