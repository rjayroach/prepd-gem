require 'optparse'

module Prepd::Cli
  class OptionsParser
    attr_accessor :options

    def initialize(options = nil)
      self.options = options || {}
    end

    def parse
      optparse = OptionParser.new do |opts|
        opts.on('-c', '--client [OPT]', 'Client') do |value|
          options['CLIENT'] = value
        end

        opts.on( '-d', '--data_dir [OPT]', 'Data directory' ) do |value|
          options['DATA_DIR'] = value
        end

        opts.on( '-p', '--project [OPT]', 'Project' ) do |value|
          options['PROJECT'] = value
        end

        opts.on('-h', '--help', 'Display this screen') do
          puts opts
          exit
        end

        opts.on('-n', '--no-op', 'Show what would happen but do not execute') do
          options.no_op = true
        end

        opts.on('-v', '--verbose', 'Display additional information') do
          options.verbose = true
        end
      end
      optparse.parse!
      options
    end
  end
end
