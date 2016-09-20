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
      table.column :repo_url, :string
    end
  end

  unless ActiveRecord::Base.connection.data_sources.include?('applications')
    create_table :applications do |table|
      table.column :project_id, :integer # foreign key <table-name-singular>_id
      table.column :name, :string
    end
  end
end
