require 'pry'
require 'prepd'
require 'prepd/cli/options_parser'
require 'prepd/cli/commands'

Prepd.options = Prepd.default_settings
Prepd.options.merge!(Prepd::Cli::OptionsParser.new.parse)
Pry.start(Prepd, prompt: [proc { 'prepd> '}])
