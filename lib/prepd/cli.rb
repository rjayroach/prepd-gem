require 'pry'
require 'prepd'
require 'prepd/cli/options_parser'
require 'prepd/cli/commands'
require 'ostruct'

module Prepd
  # Parse any command line arguments
  Prepd.cli_options = OpenStruct.new(Cli::OptionsParser.new.parse)

  # Load the default config, override with config file valuse and finally override with any command line options
  Prepd.config = OpenStruct.new(base_config.merge(cli_options.to_h))

  # Set the config.development? and config.production? values
  development_mode = (config.development && config.delete_field('development').eql?('true')) ? true : false
  config.send('production?=', !development_mode)
  config.send('development?=', development_mode)

  # Set config values based on machine probe, defaults, config file and cli arguments
  config.machine_type = machine_is_host? ? :host : :vm
  config.create_type ||= machine_is_host? ? :machine : :project
  config.config_dir = config_dir
  config.command = ARGV[0] ? ARGV.shift.to_sym : :cli

  # Prepare the database
  ActiveRecord::Base.logger = Logger.new(File.open("#{config.config_dir}/database.log", 'w'))
  ActiveRecord::Base.establish_connection(adapter: :sqlite3, database: "#{config.config_dir}/sqlite.db")
  require 'prepd/models/schema'

  # Process the command or invoke the console
  if config.command.eql?(:cli)
    Pry.start(Prepd, prompt: [proc { 'prepd> '}])
  elsif commands.include?(config.command)
    STDOUT.puts(Prepd.send(config.command))
  else
    # TODO: show the 'runtime' help
    STDOUT.puts("#{config.command} - No such command")
  end
end
