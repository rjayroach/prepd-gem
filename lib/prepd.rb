require 'prepd/version'
require 'dotenv'
require 'active_record'
require 'sqlite3'
require 'fileutils'

module Prepd
  def self.work_dir; "#{Dir.home}/.prepd"; end
  def self.data_dir; ENV['DATA_DIR']; end

  def self.files; Dir.glob("#{work_dir}/*"); end

  def self.config; "#{work_dir}/config"; end

  def self.default_settings
    {
      'VERSION' => '1',
      'DATA_DIR' => "#{Dir.home}/prepd",
      'VAGRANT_BASE_BOX' => 'debian/contrib-jessie64'
    }
  end

  # Create records for exisitng directories in the DATA_DIR
  def self.scan
    clients = Dir.entries(ENV['DATA_DIR'])
    clients.select { |entry| !entry.starts_with?('.') }.each do |client_name|
      c = Client.find_or_create_by(name: client_name)
      projects = Dir.entries("#{ENV['DATA_DIR']}/#{client_name}")
      projects.select { |entry| !entry.starts_with?('.') }.each do |project_name|
        c.projects.find_or_create_by(name: project_name)
      end
    end
  end

  FileUtils.mkdir_p work_dir
  ActiveRecord::Base.logger = Logger.new(File.open("#{work_dir}/database.log", 'w'))
  ActiveRecord::Base.establish_connection(adapter: :sqlite3, database: "#{work_dir}/sqlite.db")
  unless File.exists?(config)
    File.open(config, 'a') do |f|
      default_settings.each { |key, value| f.puts("#{key}=#{value}") }
    end
  end
  Dotenv.load(config)
end

require 'prepd/schema'
require 'prepd/models'
