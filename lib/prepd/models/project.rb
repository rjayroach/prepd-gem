module Prepd
  class Project < Base
    WORK_DIR = 'projects'
    REPOSITORY_VERSION = '0.1.1'.freeze
    REPOSITORY_NAME = 'prepd-project'.freeze

    include Prepd::Component
    # If production? then remove the .git directory in order to start with a clean repository
    # If development? then clone the master branch and return
  end
end

=begin
module Prepd
  class Project < Base

    has_many :machine_projects
    has_many :machines, through: :machine_projects

    after_save :write_config

    after_create :set_machine, :clone_repository, :write_password_file
    validates :name, presence: true, uniqueness: true  # "You must supply APP_PATH" unless name

    # Gets the machine that this project is created on and add it to the array and then save
    # Both the project and the machine are saved which triggers an update of both machine and project YAML files
    def set_machine
      Machine.ref.projects << self
      Machine.ref.save
    end

    #
    # TODO: project's ansible.cfg needs a custom path to vault_password_file
    # TODO: dir hierarchy for new projects:
    # ~/projects/hashapp/apps/devops/app/ansible
    # ~/projects/hashapp/config/vault
    # ~/prepd/config/projects/hashapp/data
    # ~/prepd/config/projects/hashapp/vars/setup.yml
    # ~/prepd/config/projects/hashapp/vault-keys
    #
    # TODO: so prepd new <project_name> does this:
    # mdkir ~/projects/<project_name>/app/ansible
    # mdkir ~/projects/<project_name>/code
    # mdkir ~/projects/<project_name>/config/vault
    #
    def clone_repository
      Dir.mkdir(name)
      Dir.chdir(name) do
        Prepd.log('cloning git project') if config.no_op
        system("git clone #{Prepd.git_log} git@github.com:rjayroach/#{self.class::REPOSITORY_NAME}.git .") unless config.no_op
        if config.production?
          Prepd.log("checking out version v#{self.class::REPOSITORY_VERSION}") if config.no_op
          tag_checkout_ok = system("git checkout #{Prepd.git_log} -b v#{self.class::REPOSITORY_VERSION} tags/v#{self.class::REPOSITORY_VERSION}") unless config.no_op
          fail "Could not checkout out tag v#{self.class::REPOSITORY_VERSION}" unless tag_checkout_ok or config.no_op
          Prepd.log('initializing new .git repository') if config.no_op
          FileUtils.rm_rf('.git') unless config.no_op
          system("git init #{Prepd.git_log}") unless config.no_op
          Prepd.log('adding all files to the first commit') if config.no_op
          system('git add .') unless config.no_op
          system("git commit #{Prepd.git_log} -m 'First commit from Prepd'") unless config.no_op
        end
      end
      nil
    end

    def write_password_file
      Prepd.create_password_file(config_dir)
    end

    # TODO: Projects have a client/project path, not just a name
    def config_dir
      "#{config.prepd_dir}/config/projects/#{name}"
    end

    # as_json with machines array included
    def for_yaml
      as_json
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
=end
