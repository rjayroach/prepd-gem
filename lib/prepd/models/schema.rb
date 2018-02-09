ActiveRecord::Schema.define do
  unless ActiveRecord::Base.connection.data_sources.include?('developers')
    create_table :developers do |table|
      table.column :name, :string
    end
  end

  unless ActiveRecord::Base.connection.data_sources.include?('machines')
    create_table :machines do |table|
      # table.column :developer_id, :integer # foreign key <table-name-singular>_id
      table.column :name, :string
      table.column :projects_dir, :string
    end
  end

  unless ActiveRecord::Base.connection.data_sources.include?('machine_projects')
    create_table :machine_projects do |table|
      table.column :machine_id, :integer # foreign key <table-name-singular>_id
      table.column :project_id, :integer # foreign key <table-name-singular>_id
    end
  end

  unless ActiveRecord::Base.connection.data_sources.include?('projects')
    create_table :projects do |table|
      table.column :name, :string
      table.column :repo_url, :string
    end
  end
end
