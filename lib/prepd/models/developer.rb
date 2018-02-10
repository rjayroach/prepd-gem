module Prepd
  class Developer < Base
    REPOSITORY_VERSION = '0.1.1'.freeze
    REPOSITORY_NAME = 'prepd'.freeze

    # attr_accessor :tf_creds, :tf_key, :tf_secret, :ansible_creds, :ansible_key, :ansible_secret
    # TODO: Rename prepd repo to prepd-docs
    # Commit everything ot prepd-developer and push
    # Change repo name to prepd
    # TODO:
    # In dev mode the directories are ~/prepd-dev/.prepd and ~/prepd-dev/prepd

    before_create :check_count
    after_create :setup_host

    def check_count
      throw :abort if self.class.count > 0
    end

    def setup_host
      binding.pry
      # setup_git  # clone prepd repo to ~/.prepd
      # create_password_file
      # clone_dependencies
      '1'
    end

    def create_password_file
      password_dir = "#{config_dir}/vault-keys"
      password_file = "#{password_dir}/password.txt"
      return if File.exists?(password_file)
      FileUtils.mkdir_p(password_dir)
      write_password_file(password_file)
    end

    def config_dir
      "#{config.prepd_dir}/config/developer"
    end

    #
    # Clone prepd-roles, terraplate and terraplate-components
    #
    def clone_dependencies
      log = config.verbose ? '' : '--quiet'
      ansible_roles_path = "#{Dir.home}/.ansible/roles"
      FileUtils.mkdir_p(ansible_roles_path)
      Dir.chdir(ansible_roles_path) do
        dependencies.each do |key, value|
          system("git clone #{log} git@github.com:rjayroach/#{key} #{value}") unless Dir.exists?("#{ansible_roles_path}/#{value}")
        end
      end
    end

    def dependencies
      {'prepd-roles' => 'prepd', 'terraplate' => 'terraplate', 'terraplate-components' => 'terraplate-components' }
    end



    ### Developer utilty methods
    def prepd_developer_config
      @prepd_developer_config ||= (
        if File.exists?(prepd_developer_config_path)
          YAML.load_file(prepd_developer_config_path)['prepd_developer']
        else
          {}
        end
      )
    end

    def write_prepd_developer_config
      FileUtils.mkdir_p(prepd_developer_path) unless Dir.exists?(prepd_developer_path)
      File.open(prepd_developer_config_path, 'w') do |f|
        f.write({ 'prepd_developer' => prepd_developer_config.to_yaml })
      end
    end

    def prepd_developer_config_path
      "#{prepd_developer_path}/prepd-developer.yml"
    end

    def prepd_developer_path
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
