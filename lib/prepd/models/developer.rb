module Prepd
  class Workspace < Base
    REPOSITORY_VERSION = '0.1.1'.freeze
    REPOSITORY_NAME = 'prepd'.freeze
    ANSIBLE_ROLES_PATH = "#{Dir.home}/.ansible/roles".freeze
    ANSIBLE_ROLES = {'prepd-roles' => 'prepd', 'terraplate' => 'terraplate', 'terraplate-components' => 'terraplate-components' }.freeze

    # attr_accessor :tf_creds, :tf_key, :tf_secret, :ansible_creds, :ansible_key, :ansible_secret
    # Steps
    # create a machine
    # boot the machine
    # run ~/prepd/app/ansible/setup.yml
    #
    # Issues
    # - database needs to be shared between VMs and the host
    # - second patch to ansible 2.4.3.0 is failing
    # - prepd/setup/tasks/main.yml just includes vars from prepd_dir/app/ansible/setup/vars.yml
    # - dev machine frank keeps provisioning everytime it boots. why?
    #
    # TODO:
    # - change --dev to more like 'workspaces' where each workspace has a set of machines, projects, etc
    # one or more of the workspaces may be used for prepd development. That is not of consequence
    # Then the host's ~/.prepd/config is still applicable to all workspaces
    # Maybe it's like this:
    # ~/prepd/workspaces/default # this is mounted in each machine as ~/prepd
    # ~/.prepd/config stores the most recent workspace which is what prepd-gem uses for things like prepd ssh
    # ~/prepd/shared  # this is where prepd-gem and other projects shared between all workspaces go
    # OR maybe all it needs is to change the option from --dev to --workspace and require a param when using
    #
    # - make shared repos, e.g. prepd-gem, rails-templates, etc availalbe to all VMs regardless of prod/dev
    # put dev dir inside ~/.prepd/host on the host
    # always mount the host's ~/.prepd/host dir in the VMs as ~/host
    #
    # - be able to change the name of the VM by changing the parent directory
    # Change the Vagrantfile to get the name of the enclosing directory as the name
    # serialize the record id to prepd-machine.yml
    # when running vagrant up it calls prepd update <record_id> <name>

    before_create :check_count
    after_create :setup_space

    def check_count
      return if self.class.count.zero?
      self.class.first.delete and return if config.force
      errors.add(:create, host: 'record exists use --force to override')
      throw :abort
    end

    def setup_space
      FileUtils.mkdir_p(config.prepd_dir) unless Dir.exists? config.prepd_dir
      Dir.chdir(config.prepd_dir) { clone_repository }
      clone_dependencies
      create_password_file
    end

    #
    # Clone Ansible roles
    #
    def clone_dependencies
      FileUtils.mkdir_p(ANSIBLE_ROLES_PATH) unless Dir.exists? ANSIBLE_ROLES_PATH
      Dir.chdir(ANSIBLE_ROLES_PATH) do
        ANSIBLE_ROLES.each do |key, value|
          next if Dir.exists? "#{ANSIBLE_ROLES_PATH}/#{value}"
          system("git clone #{git_log} git@github.com:rjayroach/#{key} #{value}")
        end
      end
    end

    def create_password_file
      password_dir = "#{config_dir}/vault-keys"
      password_file = "#{password_dir}/password.txt"
      return if File.exists?(password_file)
      FileUtils.mkdir_p(password_dir) unless Dir.exists? password_dir
      write_password_file(password_file)
    end

    def config_dir
      "#{config.prepd_dir}/config/developer"
    end



    #############
    #
    # Initialize the prepd-project or just copy in developer credentials if the project already exists
    #
    def create_project
      if Dir.exists?(path)
        copy_developer_yml
        return
      end
      setup_git
      clone_submodules
      copy_developer_yml
      generate_credentials
      encrypt_vault_files
    end

    #
    # Copy developer credentials or create them if the file doesn't already exists
    # TODO: Maybe the creation of developer creds should be done at startup of prepd
    #
    def copy_developer_yml
      return if File.exists?("#{path}/.developer.yml")
      Dir.chdir(path) do
        if File.exists?("#{Prepd.config_dir}/developer.yml")
          FileUtils.cp("#{Prepd.config_dir}/developer.yml", '.developer.yml')
        elsif File.exists?("#{Dir.home}/.prepd-developer.yml")
          FileUtils.cp("#{Dir.home}/.prepd-developer.yml", '.developer.yml')
        else
          File.open('.developer.yml', 'w') do |f|
            f.puts('---')
            f.puts("git_username: #{`git config --get user.name`.chomp}")
            f.puts("git_email: #{`git config --get user.email`.chomp}")
            f.puts("docker_username: ")
            f.puts("docker_password: ")
          end
        end
      end
    end

    #
    # Create AWS credential files for Terraform and Ansible, ssh keys and and ansible-vault encryption key
    # NOTE: The path to credentials is used in the ansible-role prepd
    #
    def generate_credentials
      # self.tf_creds = '/Users/rjayroach/Documents/c2p4/aws/legos-terraform.csv'
      # self.ansible_creds = '/Users/rjayroach/Documents/c2p4/aws/legos-ansible.csv'
      generate_tf_creds
      generate_ansible_creds
      generate_ssh_keys
      generate_vault_password
    end

    def generate_tf_creds
      self.tf_key, self.tf_secret = CSV.read(tf_creds).last.slice(2,2) if tf_creds
      unless tf_key and tf_secret
        STDOUT.puts 'tf_key and tf_secret need to be set (or set tf_creds to path to CSV file)'
        return
      end
      require 'csv'
      Dir.chdir(path) do
        File.open('.terraform-vars.txt', 'w') do |f|
          f.puts("aws_access_key_id = \"#{tf_key}\"")
          f.puts("aws_secret_access_key = \"#{tf_secret}\"")
        end
      end
    end

    def generate_ansible_creds
      self.ansible_key, self.ansible_secret = CSV.read(ansible_creds).last.slice(2,2) if ansible_creds
      unless ansible_key and ansible_secret
        STDOUT.puts 'ansible_key and ansible_secret need to be set (or set ansible_creds to path to CSV file)'
        return
      end
      Dir.chdir(path) do
        File.open('.boto', 'w') do |f|
          f.puts('[Credentials]')
          f.puts("aws_access_key_id = #{ansible_key}")
          f.puts("aws_secret_access_key = #{ansible_secret}")
        end
      end
    end

    #
    # Generate a key pair to be used as the EC2 key pair
    #
    def generate_ssh_keys(file_name = '.id_rsa')
      Dir.chdir(path) { system("ssh-keygen -b 2048 -t rsa -f #{file_name} -q -N '' -C 'ansible@#{name}.#{client.name}.local'") }
    end

    #
    # Use ansible-vault to encrypt the inventory group_vars
    #
    def encrypt_vault_files
      Dir.chdir("#{path}/ansible") do
        %w(all development local production staging).each do |env|
          system("ansible-vault encrypt inventory/group_vars/#{env}/vault")
        end
      end
    end

    def encrypt(mode = :vault)
      return unless executable?('gpg')
      Dir.chdir(path) do
        system "tar cf #{archive(:credentials)} #{file_list(mode)}"
      end
      system "gpg -c #{archive(:credentials)}"
      FileUtils.rm(archive(:credentials))
      "File created: #{archive(:credentials)}.gpg"
    end

    def encrypt_data
      return unless executable?('gpg')
      archive_path = "#{path}/#{client.name}-#{name}-data.tar"
      Dir.chdir(path) do
        system "tar cf #{archive_path} data"
      end
      system "gpg -c #{archive_path}"
      FileUtils.rm(archive_path)
      FileUtils.mv("#{archive_path}.gpg", "#{archive(:data)}.gpg")
      "File created: #{archive(:data)}.gpg"
    end

    def decrypt(type = :credentials)
      return unless %i(credentials data).include? type
      return unless executable?('gpg')
      unless File.exists?("#{archive(type)}.gpg")
        STDOUT.puts "File not found: #{archive(type)}.gpg"
        return
      end
      system "gpg #{archive(type)}.gpg"
      Dir.chdir(path) do
        system "tar xf #{archive(type)}"
      end
      FileUtils.rm(archive(type))
      "File processed: #{archive(type)}.gpg"
    end

    def executable?(name = 'gpg')
      require 'mkmf'
      rv = find_executable(name)
      STDOUT.puts "#{name} executable not found" unless rv
      FileUtils.rm('mkmf.log')
      rv
    end

    def file_list(mode)
      return ".boto .id_rsa .id_rsa.pub .terraform-vars.txt .vault-password.txt" if mode.eql?(:all)
      ".vault-password.txt"
    end

    def archive(type = :credentials)
      "#{data_path}/#{client.name}-#{name}-#{type}.tar"
    end

    def data_path
      "#{path}/data"
    end
  end
end
