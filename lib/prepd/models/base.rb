require 'yaml'
require 'erb'

module Prepd
  class Base < ActiveRecord::Base
    self.abstract_class = true

    attr_accessor :config

    after_initialize :set_config

    def set_config
      self.config = Prepd.config
    end

    def as_json(options = {})
      # super(only: [:name])
      super(only: [:id])
    end

    def kind
      self.class.name.split('::').last.downcase
    end

    def to_yaml
      { 'kind' => kind, 'data' => for_yaml }.to_yaml
    end

    def from_yaml
      File.exists?(config_file_path) ? YAML.load_file(config_file_path) : {}
    end

    def write_config
      FileUtils.mkdir_p("#{config_dir}/vars") unless Dir.exists?("#{config_dir}/vars")
      File.open(config_file_path, 'w') { |f| f.write(to_yaml) }
    end

    def config_file_path
      # "#{config_dir}/prepd-#{kind}.yml"
      "#{config_dir}/vars/setup.yml"
    end

    def git_log
      config.verbose ? '' : '--quiet'
    end

    #
    # Remove the project from the file system
    #
    def delete_config_dir
      FileUtils.rm_rf(config_dir)
    end

    #
    # Clone REPOSITORY_NAME
    # TODO: move this to prepd and pass in config so can be used by both workspace and project
    # If production? then remove the .git directory in order to start with a clean repository
    # If development? then clone the master branch and return
    #
    def clone_repository
      Prepd.log('cloning git project') if config.no_op
      system("git clone #{git_log} git@github.com:rjayroach/#{self.class::REPOSITORY_NAME}.git .") unless config.no_op
      if config.production?
        Prepd.log("checking out version v#{self.class::REPOSITORY_VERSION}") if config.no_op
        tag_checkout_ok = system("git checkout #{git_log} -b v#{self.class::REPOSITORY_VERSION} tags/v#{self.class::REPOSITORY_VERSION}") unless config.no_op
        fail "Could not checkout out tag v#{self.class::REPOSITORY_VERSION}" unless tag_checkout_ok or config.no_op
        Prepd.log('initializing new .git repository') if config.no_op
        FileUtils.rm_rf('.git') unless config.no_op
        system("git init #{git_log}") unless config.no_op
        Prepd.log('adding all files to the first commit') if config.no_op
        system('git add .') unless config.no_op
        system("git commit #{git_log} -m 'First commit from Prepd'") unless config.no_op
      end
      nil
    end

    #
    # Generate the key to encrypt ansible-vault files
    #
    def write_password_file(file_name = 'password.txt')
      require 'securerandom'
      File.open(file_name, 'w') { |f| f.puts(SecureRandom.uuid) }
      nil
    end
  end
end
