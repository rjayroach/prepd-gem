module Prepd
  class Setup < Base
    after_create :initialize_setup, :clone_ansible_roles

    def requested_dir
      "#{Dir.home}/.prepd/setup"
    end

    def initialize_setup
      Dir.mkdir_p(requested_dir)
      Dir.chdir(requested_dir) do
        FileUtils.cp_r("#{Prepd.files_dir}/setup/.", '.')
      end
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
