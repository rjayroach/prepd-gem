require 'pry'
require 'prepd'
require 'prepd/cli/options_parser'
require 'prepd/cli/commands'

Prepd.options = Prepd.default_config
Prepd.options.merge!(Prepd::Cli::OptionsParser.new.parse)

module Prepd
  if ARGV[0].eql?('new')
    create_new
  else
    Pry.start(Prepd, prompt: [proc { 'prepd> '}])
  end
end
