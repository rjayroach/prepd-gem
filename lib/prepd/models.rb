module Prepd
  class Client < ActiveRecord::Base
    attr_accessor :data_dir
    has_many :projects, dependent: :destroy
    has_many :applications, through: :projects

    before_validation :set_defaults
    validates :name, :path, presence: true

    after_create :setup

    def set_defaults
      self.path = "#{Prepd.options['DATA_DIR']}/#{name}"
    end

    def setup
      FileUtils.mkdir_p(path)
    end
  end


  class Project < ActiveRecord::Base
    attr_accessor :mode
    belongs_to :client, required: true
    has_many :applications, dependent: :destroy

    validates :name, presence: true, uniqueness: { scope: :client }

    after_create :create_project
    after_destroy :destroy_project

    #
    # Checkout the prepd-project files and remove the origin
    #
    def create_project
      Dir.chdir(client.path) { system("git clone git@github.com:rjayroach/prepd-project.git #{name}") }
      Dir.chdir(path) do
        # Remove the git history and start with a clean repository
        unless mode.eql?('dev')
          FileUtils.rm_rf("#{path}/.git")
          system('git init')
          system("git remote add origin #{repo_url}") unless repo_url.nil?
        end
        if File.exists?("#{Prepd.work_dir}/developer.yml")
          FileUtils.cp("#{Prepd.work_dir}/developer.yml", 'developer.yml')
        elsif File.exists?("#{Dir.home}/.prepd-developer.yml")
          FileUtils.cp("#{Dir.home}/.prepd-developer.yml", 'developer.yml')
        else
          File.open('developer.yml', 'w') do |f|
            f.puts('---')
            f.puts("git_username: #{system('git config --get user.name')}")
            f.puts("git_email: #{system('git config --get user.email')}")
            f.puts('docker_creds: []')
            f.puts("#  - { registry: hub.docker.com, email: user@domain, username: username, password: password }")
          end
        end
        require 'securerandom'
        File.open('.vault-password.txt', 'w') { |f| f.puts(SecureRandom.uuid) }
      end
      Dir.chdir("#{path}/ansible") do
        %w(all local development staging production).each do |env|
          system("ansible-vault encrypt inventory/group_vars/#{env}/vault")
        end
        system('git submodule add git@github.com:rjayroach/ansible-roles.git roles')
      end
    end

    # NOTE: The remote project repository will *not* be destroyed
    def destroy_project
      Dir.chdir(path) do
        system('vagrant destroy')
      end
      # TODO: If user chooses not to destroy, then don't rm_rf
      FileUtils.rm_rf(path)
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
