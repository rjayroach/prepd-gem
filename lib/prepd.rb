require 'dotenv'
require 'fileutils'
require 'active_record'
require 'sqlite3'

module Prepd
  # DEV_DIR = "#{Dir.home}/prepd-dev".freeze
  # PROD_DIR = Dir.home.freeze

  # def self.base_dir
  #   @base_dir ||= cli_options.development.eql?('true') ? (cli_options.delete_field('directory') || DEV_DIR) : PROD_DIR
  # end

  def self.config_dir; "#{Dir.home}/.prepd"; end

  def self.config_file; "#{config_dir}/config"; end

  def self.default_config
    {
      'version' => '1',
      # 'prepd_dir' => "#{base_dir}/prepd",
    }
  end

  def self.base_config
    write_config_file unless File.exists?(config_file)
    default_config.merge(Dotenv.load(config_file))
  end

  def self.write_config_file
    FileUtils.mkdir_p(config_dir) unless Dir.exists?(config_dir)
    File.open(config_file, 'w') { |f| default_config.each { |key, value| f.puts("#{key}=#{value}") } }
  end

  def self.config=(config)
    @config = config
  end

  def self.config; @config; end

  def self.cli_options=(config)
    @cli_options = config
  end

  def self.cli_options; @cli_options; end

  def self.log(message)
    STDOUT.puts(message)
  end

  def self.files_dir
    "#{Pathname.new(File.dirname(__FILE__)).parent}/files"
  end

  # Probe system for whether it is virutal or not and default accordingly
  # hostnamectl | grep Virtualization will return a string when the string is found (vm) and '' when not (host)
  # it will fail on apple machines b/c hostnamectl is not a valid command which means it is the host
  def self.machine_is_host?
    return true unless system('hostnamectl > /dev/null 2>&1')
    %x('hostnamectl').index('Virtualization').nil?
  end
end
