# Prepd

TODO: Add description of what this gem does

## Testing

### Global Setup

1. Clone ansible-roles
2. Clone this repository and cd into it
3. run echo 'This is a test!' > .vault-password.txt
4. In the Vagrantfile, uncomment test_mode = true
5. In the Vagrantfile, uncomment and change the value of testing dir to the directory where the repos were cloned

```bash
cd ~/projects
git clone git@github.com:rjayroach/ansible-roles.git
git clone git@github.com:rjayroach/prepd.git
echo 'This is a test!' > prepd/.vault-password.txt
# Edit Vagrantfile
```


### New Test Project Setup

1. Create a test project directory and cd into it
2. Softlink to this repository's Vagrantfile and bootstrap.sh file
3. run vagrant up

```bash
cd ~/projects
mkdir prepd-tests/one && cd prepd-tests/one
ln -s ~/projects/prepd/Vagrantfile
ln -s ~/projects/prepd/bootstrap.sh
vagrant up
```

### Test Project Configuration Management

1. vagrant ssh master or ssh -A 10.100.199.200
2. cd {project_name}/ansible/base
3. run the role configuration, e.g ./dev.yml


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

TODO: Write usage instructions here

## Development

After checking out the repo, run `bin/setup` to install dependencies. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/[USERNAME]/prepd. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [Contributor Covenant](http://contributor-covenant.org) code of conduct.


## License

The gem is available as open source under the terms of the [MIT License](http://opensource.org/licenses/MIT).

