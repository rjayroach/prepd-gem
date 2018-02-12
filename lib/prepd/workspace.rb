module Prepd
  class Workspace
    ANSIBLE_ROLES_PATH = "#{Dir.home}/.ansible/roles".freeze
    ANSIBLE_ROLES = {'prepd-roles' => 'prepd', 'terraplate' => 'terraplate', 'terraplate-components' => 'terraplate-components' }.freeze

    attr_accessor :config

    def initialize(config)
      self.config = config
    end

    def prepare
      if config.development?
        config.prepd_dir = Dir.pwd
      elsif in_workspace?
        config.prepd_dir = workspace_root.to_s
        prepare_database unless config.no_op
      elsif config.create_type.eql?(:project)
        config.prepd_dir = "#{Dir.home}/prepd"
        config.work_dir = Dir.pwd
        prepare_database
      else
        create_workspace
      end
    end

    def create_workspace
      check_params
      copy_workspace_files
      clone_dependencies
      Prepd.create_password_file(config_dir)
      create_developer_vars
      exit 0
    end

    def check_params
      fail 'Current directory is not a prepd workspace' if config.command != :new
      config.app_name = ARGV[0]
      fail 'Must supply APP_PATH' unless config.app_name
      config.prepd_dir = Pathname.new(config.app_name).relative? ? "#{Dir.pwd}/#{config.app_name}" : config.app_name
      fail 'Dir already exists' if Dir.exists?(config.prepd_dir)
    end

    # Create the project directory, clone the prepd repo and make the .db directory
    # TODO: Switch to using Base git clone somehow
    def copy_workspace_files
      FileUtils.mkdir_p(config.prepd_dir)
      Dir.chdir(config.prepd_dir) do
        FileUtils.cp_r("#{Prepd.files_dir}/workspace/.", '.')
        FileUtils.mkdir('.db') unless config.no_op
      end
    end

    def prepare_database
      db_dir = "#{config.prepd_dir}/.db"
      ActiveRecord::Base.logger = Logger.new(File.open("#{db_dir}/database.log", 'w'))
      ActiveRecord::Base.establish_connection(adapter: :sqlite3, database: "#{db_dir}/sqlite.db")
      require 'prepd/models/schema'
      require 'prepd/models/base'
      require 'prepd/models/machine'
      require 'prepd/models/project'
      require 'prepd/models/machine_project'
    end

    #
    # Clone Ansible roles
    #
    def clone_dependencies
      FileUtils.mkdir_p(ANSIBLE_ROLES_PATH) unless Dir.exists? ANSIBLE_ROLES_PATH
      Dir.chdir(ANSIBLE_ROLES_PATH) do
        ANSIBLE_ROLES.each do |key, value|
          next if Dir.exists? "#{ANSIBLE_ROLES_PATH}/#{value}"
          system("git clone #{Prepd.git_log} git@github.com:rjayroach/#{key} #{value}")
        end
      end
    end

    # TODO: Use YAML to load/write the file
    def create_developer_vars
      vars_dir = "#{config_dir}/vars"
      # FileUtils.mkdir_p(vars_dir) unless Dir.exists? vars_dir
      File.open("#{vars_dir}/setup.yml", 'a') do |f|
        f.puts("\ngit:")
        f.puts("  username: #{`git config --get user.name`.chomp}")
        f.puts("  email: #{`git config --get user.email`.chomp}")
      end
     end

    def config_dir
      "#{config.prepd_dir}/config/developer"
    end

    def in_workspace?
      !workspace_root.nil?
    end

    def workspace_root
      path = Pathname(Dir.pwd)
      until path.root?
        break path if Dir.exists?("#{path}/.db")
        path = path.parent
      end
    end
  end
end
