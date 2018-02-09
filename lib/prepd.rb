require 'dotenv'
require 'fileutils'
require 'active_record'
require 'sqlite3'


module Prepd
  def self.config_dir; "#{Dir.home}/.prepd"; end

  def self.config_file; "#{config_dir}/config"; end

  def self.default_config
    {
      'version' => '1',
      'prepd_dir' => "#{Dir.home}/prepd"
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

  # Probe system for whether it is virutal or not and default accordingly
  # hostnamectl | grep Virtualization will return a string when the string is found (vm) and '' when not (host)
  # it will fail on apple machines b/c hostnamectl is not a valid command which means it is the host
  def self.machine_is_host?
    return true unless system('hostnamectl > /dev/null 2>&1')
    %x('hostnamectl').index('Virtualization').nil?
  end
end
