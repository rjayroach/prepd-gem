module Prepd
  class Setup < Base
    validate :machine_is_host, :directory_cannot_exist

    after_create :initialize_setup, :clone_ansible_roles

    def machine_is_host
      return if Prepd.config.machine_type.host?
      errors.add(:machine_type, 'Setup can only run on the host machine')
    end

    def directory_cannot_exist
      return if Prepd.config.force
      errors.add(:directory_exists, requested_dir) if Dir.exists?(requested_dir)
    end

    def requested_dir
      "#{Prepd.config_dir}/setup"
    end

    def initialize_setup
      FileUtils.mkdir_p(requested_dir)
      Dir.chdir(requested_dir) do
        FileUtils.cp_r("#{Prepd.files_dir}/setup/.", '.')
      end
      Prepd.config.working_dir = Prepd.config_dir
      ws = Workspace.new(type: 'shared')
      ws.create if ws.valid?
    end

    # TODO: add OS detection
    # TODO: Externalize next two values to a yaml file?
    ANSIBLE_ROLES_PATH = "#{Dir.home}/.ansible/roles".freeze
    ANSIBLE_ROLES = {'prepd-roles' => 'prepd', 'terraplate' => 'terraplate', 'terraplate-components' => 'terraplate-components' }.freeze

    #
    # Clone Ansible roles
    #
    def clone_ansible_roles
      FileUtils.mkdir_p(ANSIBLE_ROLES_PATH) unless Dir.exists? ANSIBLE_ROLES_PATH
      Dir.chdir(ANSIBLE_ROLES_PATH) do
        ANSIBLE_ROLES.each do |key, value|
          next if Dir.exists? "#{ANSIBLE_ROLES_PATH}/#{value}"
          system("git clone #{Prepd.git_log} git@github.com:rjayroach/#{key} #{value}")
        end
      end
    end
  end
end
