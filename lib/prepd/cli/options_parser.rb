require 'optparse'

module Prepd::Cli
  class OptionsParser
    attr_accessor :options

    def initialize(options = nil)
      self.options = options || {}
    end

    def parse
      optparse = OptionParser.new do |opts|
        opts.banner = "Usage:\n  prepd new AAP_PATH [options]\n\nOptions:"

        opts.on( '--dev', '# Create in development context' ) do |value|
          options['ENV'] = 'DEV'
        end

        opts.on( '--prod', '# Create in production context' ) do |value|
          options['ENV'] = 'PROD'
        end

        opts.on( '-m', '--machine', '# Create a new virtual machine' ) do |value|
          options['CREATE_TYPE'] = 'machine'
        end

        opts.on( '-p', '--project', '# Create a new project' ) do |value|
          options['CREATE_TYPE'] = 'project'
        end

        opts.on('-h', '--help', '# Display this screen') do
          puts opts
          puts "\nExample:\n   prepd new ~/my/new/project\n"
          puts "\n   This generates a skeletal prepd installation in ~/my/new/project"
          exit
        end

        opts.on('-n', '--no-op', '# Show what would happen but do not execute') do
          options['no_op'] = true
        end

        opts.on('-v', '--verbose', '# Display additional information') do
          options['verbose'] = true
        end
      end
      optparse.parse!
      options
    end
  end
end
