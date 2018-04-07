require 'pry'
require 'ostruct'
require 'prepd/cli/options_parser'
require 'prepd/cli/commands'

module Prepd
  # Parse any command line arguments
  Prepd.cli_options = OpenStruct.new(Cli::OptionsParser.new.parse)

  # Load the default config, override with config file valuse and finally override with any command line options
  Prepd.config = OpenStruct.new(base_config.merge(cli_options.to_h))
  config.command = StringInquirer.new(ARGV[0] ? ARGV.shift : 'cli')
  # config.config_dir = config_dir

  config.env = StringInquirer.new(Prepd.cli_options.env || 'production' )
  config.working_dir ||= Dir.pwd

  # Set config values based on machine probe, defaults, config file and cli arguments
  config.machine_type = StringInquirer.new(machine_is_host? ? 'host' : 'vm')
  Prepd.verify_workspaces

  # Process the command or invoke the console
  if config.command.cli?
    Pry.start(Prepd::Command, prompt: [proc { 'prepd> '}])
  elsif Command.methods(false).include?(config.command.to_sym)
    STDOUT.puts(Command.send(config.command))
  else
    # TODO: show the 'runtime' help
    STDOUT.puts("#{config.command} - No such command. Valid commands are #{Command.methods(false).join(', ')}")
  end
end
