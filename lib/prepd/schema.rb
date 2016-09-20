ActiveRecord::Schema.define do
  unless ActiveRecord::Base.connection.data_sources.include?('clients')
    create_table :clients do |table|
      table.column :name, :string
      table.column :path , :string
    end
  end

  unless ActiveRecord::Base.connection.data_sources.include?('projects')
    create_table :projects do |table|
      table.column :client_id, :integer # foreign key <table-name-singular>_id
      table.column :name, :string
    end
  end

  unless ActiveRecord::Base.connection.data_sources.include?('applications')
    create_table :applications do |table|
      table.column :project_id, :integer # foreign key <table-name-singular>_id
      table.column :name, :string
    end
  end
end

module Prepd
  # Client has_many projects; Project has_many applications
  class Client < ActiveRecord::Base
    attr_accessor :data_dir
    has_many :projects
    has_many :applications, through: :projects
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

  class Project < ActiveRecord::Base
    belongs_to :client, required: true
    has_many :applications
    validates :name, presence: true, uniqueness: { scope: :client }
    after_create :setup

    #
    # Copy files from the prepd/files directory
    #
    def setup
      FileUtils.cp_r(files_path, path)
    end

    def files_path
      "#{__dir__}/../../files"
    end

    def path
     "#{client.path}/#{name}"
    end
  end



  class Application < ActiveRecord::Base
    belongs_to :project, required: true
    validates :name, presence: true, uniqueness: { scope: :project }
    after_create :setup

    def setup
      FileUtils.mkdir_p(path)
    end

    def path
     "#{project.path}/ansible/#{name}"
    end
  end
end
