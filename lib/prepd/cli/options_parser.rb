require 'optparse'

module Prepd::Cli
  class OptionsParser
    def parse
      options = OpenStruct.new
      optparse = OptionParser.new do |opts|
        opts.banner = "Usage:\n  prepd new AAP_PATH [options]\n\nOptions:"

        opts.on( '--dev', '# Setup the application with development repositories' ) do |value|
          options.env = 'development'
        end

        opts.on('-h', '--help', '# Display this screen') do
          puts opts
          puts "\nExample:\n   prepd new ~/my/new/project\n"
          puts "\n   This generates a skeletal prepd installation in ~/my/new/project"
          exit
        end

        opts.on( '-m', '--machine', '# Create a new virtual machine' ) do |value|
          options.create_type = 'machine'
        end

        opts.on('-n', '--no-op', '# Show what would happen but do not execute') do
          options.no_op = true
        end

        opts.on( '-p', '--project', '# Create a new project' ) do |value|
          options.create_type = 'project'
        end

        opts.on( '--prod', '# Setup the application with production repositories' ) do |value|
          options.env = 'production'
        end

        opts.on('-v', '--verbose', '# Display additional information') do
          options.verbose = true
        end
      end
      optparse.parse!
      options.to_h
    end
  end
end
