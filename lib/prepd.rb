require 'dotenv'
require 'fileutils'

module Prepd
  def self.config_dir; "#{Dir.home}/.prepd"; end

  def self.config_file; "#{config_dir}/config"; end

  def self.default_config
    {
      'version' => '1',
      'create_type' => 'project',
      'env' => 'production'
    }
  end

  def self.base_config
    default_config.merge(Dotenv.load(config_file))
  end

  def self.config=(config)
    @config = config
  end

  def self.config; @config; end

  def self.log(message)
    STDOUT.puts(message)
  end

  class NewObject
    attr_accessor :config

    def initialize
      self.config = Prepd.config
    end

    #
    # Clone prepd-project, remove the git history and start with a clean repository
    #
    def setup_git
      log = config.verbose ? '' : '--quiet'
      Prepd.log('cloning git project') if config.no_op
      system("git clone #{log} git@github.com:rjayroach/prepd-#{repository}.git .") unless config.no_op
      if config.production
        Prepd.log("checking out version v#{repository_version}") if config.no_op
        tag_checkout_ok = system("git checkout #{log} -b v#{repository_version} tags/v#{repository_version}") unless config.no_op
        fail "Could not checkout out tag v#{repository_version}" unless tag_checkout_ok or config.no_op
      end
      Prepd.log('initializing new .git repository') if config.no_op
      FileUtils.rm_rf('.git') unless config.no_op
      system("git init #{log}") unless config.no_op
      Prepd.log('adding all files to the first commit') if config.no_op
      system('git add .') unless config.no_op
      system("git commit #{log} -m 'First commit from Prepd'") unless config.no_op
      nil
    end
  end
end
