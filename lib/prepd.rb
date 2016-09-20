require 'prepd/version'
require 'dotenv'
require 'active_record'
require 'sqlite3'

module Prepd
  def self.work_dir; "#{Dir.home}/.prepd"; end
  def self.data_dir; ENV['DATA_DIR']; end

  def self.files; Dir.glob("#{work_dir}/*"); end

  def self.rm
    FileUtils.rm_rf(work_dir)
    FileUtils.rm_rf(data_dir)
  end

  def self.config; "#{work_dir}/config"; end
  def self.clients; Client.pluck(:name); end
  def self.projects; Project.pluck(:name); end

  def self.current_client
    @client
  end

  def self.current_client=(client)
    STDOUT.puts 'duh'
    @client = client
    Dir.chdir(client.path) do
      Pry.start(client, prompt: [proc { "prepd(#{client.name}) > " }])
    end
    STDOUT.puts 'duh2'
    nil
  end

  def self.default_settings
    {
      'DATA_DIR' => "#{Dir.home}/prepd",
      'VAGRANT_BASE_BOX' => 'debian/contrib-jessie64'
    }
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
  # STDOUT.puts ENV['DATA_DIR']
  # STDOUT.puts ENV['VAGRANT_BASE_BOX']
end

require 'prepd/schema'
