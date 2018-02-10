module Prepd
  class Machine < Base
    VAGRANTFILE = 'Vagrantfile'.freeze
    NAME = %x(hostname -f).split('.')[1].freeze

    has_many :machine_projects
    has_many :projects, through: :machine_projects

    after_save :write_vagrantfile, :write_config
    before_destroy :destroy_vm, :delete_config_dir

    validates :name, presence: true, uniqueness: true  # "You must supply APP_PATH" unless name

    def self.ref
      find_by(name: NAME)
    end

    def write_vagrantfile
      FileUtils.mkdir_p(config_dir) unless Dir.exists?(config_dir)
      File.open("#{config_dir}/#{VAGRANTFILE}", 'w') { |f| f.write(ERB.new(vagrantfile_template).result(binding)) }
    end

    def vagrantfile_template
      File.read(File.join(File.dirname(__FILE__), VAGRANTFILE))
    end

    #
    # Destory the VM
    #
    def destroy_vm
      yes = options.yes ? ' --yes' : ''
      processed = nil
      Dir.chdir(config_dir) { processed = system("vagrant destroy#{yes}") }
      # TODO: If the vagrant destory is canceled then immediately return from this method
      unless processed
        errors.add(:destroy, vm: 'error destroying virutal machine')
        throw :abort
      end
    end

    def config_dir
      "#{config.prepd_dir}/config/machines/#{name}"
    end

    # as_json with projects array included
    def for_yaml
      as_json.merge({ 'projects' => projects.as_json })
    end


    # attr_accessor :tf_creds, :tf_key, :tf_secret, :ansible_creds, :ansible_key, :ansible_secret
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
  end
end
