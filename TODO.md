# TODO

- option to just gpg encrypt ansible-vault.txt rather than the full set of credentials
- move gpg files to the project's data dir instead of user's home dir
- add an option to tar, gizp and gpg the data directory as well

- update prepd-project readme when cloning existing to also pull in ansible-roles


- create a bootstrap.sh script that installs Ansible and dependencies, e.g. Homebrew, python, etc
- add a playbook that provisions a mac or ubuntu laptop with android, packer, extras, etc

- update README to document provisioning a mac (and ubuntu) from brand new:
1. git clone prepd
2. run bootstrap.sh
3. run ./laptop.yml
4. bin/console to create a client and project OR git clone a project created with prepd
