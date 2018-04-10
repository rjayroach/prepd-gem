require 'optparse'

module Prepd::Cli
  class OptionsParser
    def parse
      options = OpenStruct.new
      optparse = OptionParser.new do |opts|
        opts.banner = "Usage:\n  prepd new AAP_PATH [options]\n\nOptions:"

        opts.on( '--bump=LEVEL', '# Setup the application with development repositories' ) do |value|
          options.bump = value
        end

        opts.on( '--cd=CONFIG_DIR', '# Run from the configuration in directory' ) do |value|
          options.config_dir = value
        end

        opts.on( '--push', '# Push the box to remote S3 bucket' ) do
          options.push = true
        end

        opts.on( '--dev', '# Setup the application with development repositories' ) do |value|
          options.env = 'development'
        end

        opts.on( '--dir=DIR', '# Set the working directory' ) do |value|
          options.working_dir = value
        end

        opts.on( '--force', '# Force operation even if it will cause errors' ) do |value|
          options.force = true
        end

        opts.on('-h', '--help', '# Display this screen') do
          # TODO: If Dir.pwd is a prepd project then putput the 'runtime' commands here
          # Otherwise output the 'prepd new --help' is appropriate
          puts opts
          puts "\nExample:\n   prepd new ~/my/new/project\n"
          puts "\n   This generates a skeletal prepd installation in ~/my/new/project"
          exit
        end

        opts.on( '-m', '--machine', '# Create a new virtual machine' ) do |value|
          options.create_type = :machine
        end

        opts.on('-n', '--no-op', '# Show what would happen but do not execute') do
          options.no_op = true
          options.verbose = true
        end

        opts.on( '-p', '--project', '# Create a new project' ) do |value|
          options.create_type = :project
        end

        opts.on('-v', '--verbose', '# Display additional information') do
          options.verbose = true
        end

        opts.on('--yes', '# Automatically say yes') do
          options.yes = true
        end
      end
      optparse.parse!
      options.to_h
    end
  end
end
