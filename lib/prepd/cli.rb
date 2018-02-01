require 'pry'
require 'prepd'
require 'prepd/cli/options_parser'
require 'prepd/cli/commands'
require 'ostruct'

module Prepd
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
  config.mode = ARGV[0].eql?('new') ? :create : :cli
  config.production = true if config.env.eql?('production')
  config.development = true if config.env.eql?('development')

  # Invoke the appropriate action
  case config.mode
  when :create
    config.app_path = ARGV[1]
    create_new
  when :cli
    Pry.start(Prepd, prompt: [proc { 'prepd> '}])
  end
end
