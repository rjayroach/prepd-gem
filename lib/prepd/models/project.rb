module Prepd
  class Project < Base
    REPOSITORY_VERSION = '0.1.1'.freeze
    REPOSITORY_NAME = 'prepd-project'.freeze

    has_many :machine_projects
    has_many :machines, through: :machine_projects

    after_save :write_config
    # TODO:
    # The git repo needs to be cloned in the proper directory in the VM; not the same as the config directory

    after_create :set_machine
    validates :name, presence: true, uniqueness: true  # "You must supply APP_PATH" unless name

    # Get the machine that this project is created on and add it to the array and then save
    # Both the project and the machine should be saved forcing an update of the YAML files
    def set_machine
      Machine.ref.projects << self
      Machine.ref.save
    end

    # TODO: Projects have a client/project path, not just a name
    def config_dir
      "#{config.prepd_dir}/config/projects/#{name}"
    end

    # as_json with machines array included
    def for_yaml
      as_json #.merge({ 'machines' => machines.as_json })
    end

    def setup_git_x
      Dir.mkdir(name)
      Dir.chdir(name) { setup_git }
    end

    # If credentials=host then
    # Make a directory on the host for this project's credentials
    # Link to the host's config directory
    # def setup_config
    #   if config.credentials.eql?('host')
    #     dir = "#{config.host_dir}/#{config.app_name}/credentials".gsub('~', Dir.home)
    #     FileUtils.mkdir_p(dir)
    #     Dir.chdir('config') do
    #       FileUtils.ln_s(dir, 'credentials')
    #     end
    #   end
    # end
  end
end
