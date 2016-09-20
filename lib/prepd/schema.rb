ActiveRecord::Schema.define do
  unless ActiveRecord::Base.connection.data_sources.include?('clients')
    create_table :clients do |table|
      table.column :name, :string
      table.column :path , :string
    end
  end

  unless ActiveRecord::Base.connection.data_sources.include?('projects')
    create_table :projects do |table|
      table.column :client_id, :integer # foreign key <table-name-singular>_id (i.e. this is the primary key from the 'albums' table)
      table.column :name, :string
    end
  end
end

module Prepd
  class Client < ActiveRecord::Base
    attr_accessor :data_dir
    has_many :projects
    before_validation :set_defaults
    validates :name, :path, presence: true
    after_create :setup
    # after_find :set_current_client

    def set_defaults
      self.data_dir ||= ENV['DATA_DIR']
      self.path = "#{data_dir}/#{name}"
    end

    def setup
      FileUtils.mkdir_p(path)
    end

    def set_current_client
      STDOUT.puts 'after find'
      Prepd.current_client = self
    end
  end

  class Project< ActiveRecord::Base
    belongs_to :client, required: true
    validates :name, presence: true
    after_create :setup

    def setup
      FileUtils.mkdir_p("#{client.path}/#{name}")
    end
  end
end
