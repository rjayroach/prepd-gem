# Setup Host

## MacOS

This assumes a 'clean' MacOS installation of High Sierra or later. To wipe a mac see apple support documents [here](http://support.apple.com/kb/PH13871) and [here](http://support.apple.com/en-us/HT201376)

Install command line tools, e.g. git

```bash
xcode-select --install
```

Install Homebrew

```bash
ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"
```

### Install Ansible

```bash
brew install python
pip install ansible
```

## Debian/Ubuntu

### Install Ansible
```bash
apt-get install ansible
```


# Configure Host via Ansible

```bash
git clone https://github.com/rjayroach/ansible-roles
cd ansible-roles
./laptop.yml -i 'localhost,' -c local
```

# Other Stuff

## General
- Copy ssh keypair to ~/.ssh

## MacOS

### Enable SSH Server

Go to System Preferences -> Sharing, enable Remote Login.

### iTerm2 Preferences
- General: Window Section: Uncheck 'Native full screen windows'
- Appearance: Tab bar location: Bottom;  Theme: Dark
- Profiles: Colors => Load Presets to pick Solarized Dark

## Chrome Extensions
- Lastpass
- Vimium
- Ember Inspector
- AdBlock Plus
- Harvest

## Git Projects
- prepd-project
- terraform-modules


## rbenv
xcode-select --install
brew install rbenv
curl -fsSL https://github.com/rbenv/rbenv-installer/raw/master/bin/rbenv-doctor | bash
