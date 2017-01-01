module Prepd
  class Client < ActiveRecord::Base
    attr_accessor :data_dir

    has_many :projects, dependent: :destroy
    has_many :applications, through: :projects

    before_validation :set_defaults
    validates :name, :path, presence: true

    after_create :setup
    after_destroy :destroy_client

    def set_defaults
      self.path = "#{Prepd.options['DATA_DIR']}/#{name}"
    end

    def setup
      FileUtils.mkdir_p(path) unless Dir.exists?(path)
    end

    def destroy_client
      FileUtils.rm_rf("#{path}")
    end
  end


  class Project < ActiveRecord::Base
    attr_accessor :tf_creds, :tf_key, :tf_secret, :ansible_creds, :ansible_key, :ansible_secret

    belongs_to :client, required: true
    has_many :applications, dependent: :destroy

    validates :name, presence: true, uniqueness: { scope: :client }

    after_create :create_project
    after_destroy :destroy_project

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
    # Destory the VM and remove the project from the file system
    #
    def destroy_project
      Dir.chdir(path) { system('vagrant destroy') }
      FileUtils.rm_rf(path)
    end

    #
    # Clone prepd-project, remove the git history and start with a clean repository
    #
    def setup_git
      Dir.chdir(client.path) { system("git clone git@github.com:rjayroach/prepd-project.git #{name}") }
      Dir.chdir(path) do
        FileUtils.rm_rf("#{path}/.git")
        system('git init')
        system('git add .')
        system("git commit -m 'First commit from Prepd'")
        system("git remote add origin #{repo_url}") if repo_url
      end
    end

    #
    # Clone ansible roles and terraform modules
    #
    def clone_submodules
      Dir.chdir("#{path}/ansible") do
        system('git submodule add git@github.com:rjayroach/ansible-roles.git roles')
      end
      Dir.chdir("#{path}/terraform") do
        system('git submodule add git@github.com:rjayroach/terraform-modules.git modules')
      end
    end

    #
    # Copy developer credentials or create them if the file doesn't already exists
    # TODO: Maybe the creation of developer creds should be done at startup of prepd
    #
    def copy_developer_yml
      return if File.exists?("#{path}/.developer.yml")
      Dir.chdir(path) do
        if File.exists?("#{Prepd.work_dir}/developer.yml")
          FileUtils.cp("#{Prepd.work_dir}/developer.yml", '.developer.yml')
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
    # Generate the key to encrypt ansible-vault files
    #
    def generate_vault_password(file_name = '.vault-password.txt')
      require 'securerandom'
      Dir.chdir(path) { File.open(file_name, 'w') { |f| f.puts(SecureRandom.uuid) } }
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

    def path
     "#{client.path}/#{name}"
    end
  end


  class Application < ActiveRecord::Base
    belongs_to :project, required: true

    validates :name, presence: true, uniqueness: { scope: :project }

    after_create :setup

    def setup
      Dir.chdir("#{project.path}/ansible") do
        FileUtils.cp_r('application', name)
      end
    end

    def path
     "#{project.path}/ansible/#{name}"
    end
  end
end
