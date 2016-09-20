# Prepd

Prepd - A Production Ready Environment for Project Development

One of the core principles of Agile Development is delivering viewable results
to the business from Week 1. Too often product developement begins with the
application software, while the infrastructure to deploy into is addressed as
and when it is needed.

Thankfully, many web application products get to market on similar,
if not identical, infrastructure. However setting up this infastructure takes time,
is error prone and typically is non-repeatable ending up as a unique snowflake.

Therefore, many development teams use a PaaS such as Heroku. This has limitations
and only addresses the final deployment infrastructure

Prepd aims to address this by providing a 'convention over configruation' approach
to provisioning infrastructure. From local developer machines (vagrant running linux
on the developer's laptop) to staging and production running a docker swarm cluster.

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
- Load Balancing is already be setup
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

Swarm Load Balancing
- network overlays
- load balancing between micro services
- manage cluster scaling with compose/swarm mode/ansible or some combination thereof

## Projects


### Applications


## Environments

Start with both local and development (development is cloud based instance running app software)


## Installation

Add this line to your application's Gemfile:

```ruby
gem 'prepd'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install prepd

## Usage

### Connect to local machine

1. vagrant ssh master or ssh -A 10.100.199.200
2. cd {project_name}/ansible/project
3. run the role configuration, e.g ./dev.yml


## Development

After checking out the repo, run `bin/setup` to install dependencies. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/[USERNAME]/prepd. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [Contributor Covenant](http://contributor-covenant.org) code of conduct.


## License

The gem is available as open source under the terms of the [MIT License](http://opensource.org/licenses/MIT).

