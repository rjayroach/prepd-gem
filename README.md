# Prepd

Prepd - A Production Ready Environment for Project Development

One of the core principles of Agile Development is delivering viewable results
to the business from Week 1. Too often product developement begins with the
application software, while the infrastructure to deploy into is addressed as
and when it is needed.

Thankfully, many web application products get to market on similar,
if not identical, infrastructure. However setting up this infastructure takes time,
is error prone and typically is non-repeatable ending up as a unique snowflake.

To avoid this, many development teams turn to a PaaS service such as Heroku.
This has limitations and only addresses the final deployment infrastructure.

Prepd aims to address this by providing a 'convention over configruation' approach
to provisioning infrastructure. From local developer machines (vagrant running linux
on the developer's laptop) to staging and production running a docker swarm cluster.

With microservice becoming a strategy for a significant number of projects, prepd
aims to make it dead simple to build and deploy a microservice base application.

Beginning with the end in mind, Prepd offers a simple, conventional way to provision
all this infrastructure, including CI workflow, secrets managment, 12-factor apps

Agile Development requires 'near production' infrastructure to be in place from Day 1.
Using Prepd, makes that possible quickly and easily without resorting to a PaaS provider.

## Opinions

By operating with a strong opinion, Prepd focuses on supporting best of breed products
and best practices with relatively less effort. Configurable and pluggable architecture
is a secondary goal to getting something up and running. Therefore, choices are made:

- Infrastructure is Vagrant on local machines and AWS in the cloud
- Ansible is the automation tool used to configure the infrastructure
- Current product support: nginx, postgres, redis
- Current project support: rails, emberjs

## What is a Production Ready Environment?

It takes a lot of services tuned to work together to make smoothly running infrastructure

### Networking
- Domain names figured out and DNS running on Route53 etc
- Ability to programatically change and update DNS
- SSL certs are already installed so we do TLS from the beginning; even on local development
- Load Balancing is setup, configured and running in at least staging and production, but also possible in development
- HAProxy setup

### Development Services
- CI is setup and an automated deploy process is used from the outset of the project
- how are containers getting built? by quay.io, circleCI, jenkins?
- If CircleCI is building the containers and testing them then on success, where are containers going?
- If using master, develop, feature branch setup then when does the container get built?
- Prepd should anticipate that many types of CIs could be plugged in here

### Application Services
- Communication Services, e.g. SMTP, SNS (Push), Slack webhooks, Twilio, etc
- Logging in both local/development and in staging/production with ELK
- Monitoring/alert service
- Additional required 3rd party services (if already known) are configured, setup and tested
- Prepd wiki template provides a checklist that itemizes these tasks

### Swarm Load Balancing
- network overlays
- load balancing between micro services
- manage cluster scaling with compose/swarm mode/ansible or some combination thereof


## Installation

Add this line to your application's Gemfile:

```ruby
gem 'prepd'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install prepd

### Dependencies

prepd leverages a few projects to build and manage the environments.

- VirtualBox

TODO: Notes to install VirtualBox

- Vagrant

TODO: Notes to install Vagrant

```bash
vagrant plugin install vagrant-vbguest      # keep your VirtualBox Guest Additions up to date
vagrant plugin install vagrant-cachier      # caches guest packages
vagrant plugin install vagrant-hostmanager  # updates /etc/hosts file when machines go up/down
```


- Ansible

Tested with version 2.1.1

#### Install on MacOS

If planning to install on a clean machine:
1. Wipe Mac: http://support.apple.com/kb/PH13871  OR http://support.apple.com/en-us/HT201376
2. Create New User with Admin rights

Install Homebrew:

``bash
ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"
``

Install python with zlib and ssl support

```bash
xcode-select --install
brew install openssl
brew link openssl --force
brew uninstall python
brew install python --with-brewed-openssl
sudo easy_install pip
sudo pip install -U ansible
sudo pip install -U setuptools cryptography markupsafe
sudo pip install -U ansible boto
```

#### Install on Ubuntu

```bash
apt-get install ansible
```


## Definining the Actors

A Client may have multiples projects. Applications share common infrastructure that is defined by the Project

- Client: An organization with one or more projects, e.g Acme Corp
- Project: A definition of infrastructure provided for one or more applications
- Application: A logical group of deployable repositories, e.g. a Rails API server and an Ember web client


### Projects

A project is comprised of infrastructure and applications
Project infrastructure is defined separately for multiple environments
Applications are deployed into infrastructure specific to an environment

### Infrastructure

Vagrant machines
EC2 instances
Docker swarm network

### Environments

- local: virtual machines running on laptop via vagrant whose primary purpose is application development
- development: primary purpose is also application development, but the infrastructure is deployed in the cloud (AWS)
- staging: a mirror of production in every way with the possible exception of reduced or part-time resources
- production: production ;-)

### Applications

Application are the content that actually gets deployed. The entire purpose of prepd is to provide a consistent
and easy to manage infrastructure for each environment into which the application will be deployed.

## Usage

### Create a Client Project and Application

```bash
bin/console
client = Client.create(name: 'first client')
project = client.projects.create(name: 'first project')
# application = project.applications.create(name: 'first application')
```

NOTE: Maybe application isn't necessary?


## Development

After checking out the repo, run `bin/setup` to install dependencies. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/[USERNAME]/prepd. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [Contributor Covenant](http://contributor-covenant.org) code of conduct.


## License

The gem is available as open source under the terms of the [MIT License](http://opensource.org/licenses/MIT).

