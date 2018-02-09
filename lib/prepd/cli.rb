require 'pry'
require 'prepd'
require 'prepd/cli/options_parser'
require 'prepd/cli/commands'
require 'ostruct'

module Prepd
  # Prepare the database
  ActiveRecord::Base.logger = Logger.new(File.open("#{config_dir}/database.log", 'w'))
  ActiveRecord::Base.establish_connection(adapter: :sqlite3, database: "#{config_dir}/sqlite.db")
  require 'prepd/models/schema'

  # Write the config file if it does not exist
  FileUtils.mkdir_p(config_dir) unless Dir.exists?(config_dir)
  unless File.exists?(config_file)
    File.open(config_file, 'a') do |f|
      default_config.each { |key, value| f.puts("#{key}=#{value}") }
    end
  end

  # Parse any command line arguments
  cli_options = Cli::OptionsParser.new.parse
  Prepd.config = OpenStruct.new(base_config.merge(cli_options))

  # Are we in development or production?
  development_mode = (config.development && config.delete_field('development').eql?('true')) ? true : false
  config.send('production?=', !development_mode)
  config.send('development?=', development_mode)

  # Set config values based on machine probe, defaults, config file and cli arguments
  config.machine_type = machine_is_host? ? :host : :vm
  config.create_type ||= machine_is_host? ? :machine : :project
  config.command = ARGV[0] ? ARGV.shift.to_sym : :cli

  # Invoke the appropriate action
  if config.command.eql?(:cli)
    Pry.start(Prepd, prompt: [proc { 'prepd> '}])
  else
    begin
      STDOUT.puts(Prepd.send(config.command))
    # rescue NoMethodError => e
    #   STDOUT.puts('No such command')
    end
  end
end
