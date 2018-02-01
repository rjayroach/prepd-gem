require 'dotenv'
require 'fileutils'

module Prepd
  def self.config_dir; "#{Dir.home}/.prepd"; end

  def self.files; Dir.glob("#{config_dir}/*"); end

  def self.config_file; "#{config_dir}/config"; end

  def self.default_config
    {
      'VERSION' => '1',
      'CREATE_TYPE' => 'project',
      'ENV' => 'dev'
    }
  end

  # TODO: Probe system for whether it is virutal or not and default accordingly
  # # hostnamectl status | grep Virtualization will return 0 when found (vm) and 1 when not (host)
  def self.create_new
    require "prepd/#{options['CREATE_TYPE']}"
    project_path = ARGV[1]
    fail "Path '#{project_path}' already exists!" if Dir.exists?(project_path)
    obj = Kernel.const_get("Prepd::#{Prepd.options['CREATE_TYPE'].capitalize}").new(path: project_path, env: Prepd.options['ENV'])
    FileUtils.mkdir_p(project_path)
    Dir.chdir(project_path) { STDOUT.puts obj.create }
  end
end

module Prepd
  class NewObject
    attr_accessor :path, :env

    def initialize(path:, env:)
      self.path = path
      self.env = env
    end
  end
end

module Prepd
  FileUtils.mkdir_p(config_dir)
  unless File.exists?(config_file)
    File.open(config_file, 'a') do |f|
      default_config.each { |key, value| f.puts("#{key}=#{value}") }
    end
  end
  Dotenv.load(config_file)
end
