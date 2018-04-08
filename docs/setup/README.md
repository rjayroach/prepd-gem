## Setup Host

### MacOS

This assumes a 'clean' MacOS installation of High Sierra or later. To wipe a mac see apple support documents [here](http://support.apple.com/kb/PH13871) and [here](http://support.apple.com/en-us/HT201376)

Additional notes on installing macOS from a USB device [here](https://support.apple.com/en-sg/HT201372) and [here](https://support.apple.com/en-sg/HT201475)

Install command line tools, e.g. git

```bash
xcode-select --install
```

Install Homebrew

```bash
ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"
```

Install python3 and ansible

```bash
brew install python
pip3 install ansible
```

Install Prepd

```bash
brew install rbenv
```

### Debian / Ubuntu

Install Ansible and rbenv

```bash
apt-get install ansible rbenv
```

## Install and setup prepd

```bash
rbenv install 2.5.1
```

Run rbenv doctor, follow the instructions to source rbenv in your shell profile

```bash
curl -fsSL https://github.com/rbenv/rbenv-installer/raw/master/bin/rbenv-doctor | bash
```

Open a new terminal window and install prepd

```bash
gem install prepd
```

Check out the README.md in ~/.prepd/setup/README.md

```bash
prepd setup
```


# Miscellaneous Mentions

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
