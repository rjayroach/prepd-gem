require 'fileutils'
require 'active_record'

module Prepd
  class StringInquirer < String
    # Copied from ActiveSupport::StringInquirer
    def method_missing(method_name, *arguments)
      if method_name[-1] == '?'
        self == method_name[0..-2]
      else
        super
      end
    end
  end

  def self.env; @env; end
  def self.env=(env); @env = env; end

  def self.config_dir; @config_dir end

  def self.config_dir=(dir)
    @config_dir = dir
  end

  def self.config_file; "#{config_dir}/config.yml"; end

  def self.default_config
    { version: 1 }
  end

  def self.register_workspace(dir)
    config.workspaces << dir
    write_config_file
  end

  def self.verify_workspaces
    config.workspaces ||= []
    config.workspaces.each do |dir|
      next if File.exists?(File.expand_path("#{dir}/prepd-workspace.yml"))
      config.workspaces -= [dir]
    end
    write_config_file
  end

  def self.base_config
    write_config_file unless File.exists?(config_file)
    default_config.merge(YAML.load(File.read(config_file)))
  end

  def self.write_config_file
    FileUtils.mkdir_p(config_dir) unless Dir.exists?(config_dir)
    File.open(config_file, 'w') { |f| f.write(YAML.dump(writable_config)) }
  end

  def self.writable_config
    config.to_h.select { |k| %i(version workspaces).include?(k) }
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


  def self.create_password_file(config_dir)
    password_dir = "#{config_dir}/vault-keys"
    password_file = "#{password_dir}/password.txt"
    return if File.exists?(password_file)
    FileUtils.mkdir_p(password_dir) unless Dir.exists? password_dir
    write_password_file(password_file)
  end

  #
  # Generate the key to encrypt ansible-vault files
  #
  def self.write_password_file(file_name = 'password.txt')
    require 'securerandom'
    File.open(file_name, 'w') { |f| f.puts(SecureRandom.uuid) }
    nil
  end

  def self.git_log
    config.verbose ? '' : '--quiet'
  end
end
