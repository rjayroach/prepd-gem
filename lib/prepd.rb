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
  end
end
