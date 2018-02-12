ActiveRecord::Schema.define do
  unless ActiveRecord::Base.connection.data_sources.include?('machines')
    create_table :machines do |t|
      # t.column :developer_id, :integer # foreign key <table-name-singular>_id
      t.column :name, :string
      t.column :projects_dir, :string
      t.timestamps
    end
  end

  unless ActiveRecord::Base.connection.data_sources.include?('machine_projects')
    create_table :machine_projects do |t|
      t.column :machine_id, :integer # foreign key <table-name-singular>_id
      t.column :project_id, :integer # foreign key <table-name-singular>_id
      t.timestamps
    end
  end

  unless ActiveRecord::Base.connection.data_sources.include?('projects')
    create_table :projects do |t|
      t.column :name, :string
      t.column :repo_url, :string
      t.timestamps
    end
  end
end
