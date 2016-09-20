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
        # TODO: Put a field in table for git repo url then add a "git remote add origin #{url}"
        system('git remote rm origin') unless mode.eql?('test')
        require 'securerandom'
        File.open('.vault-password.txt', 'w') { |f| f.puts(SecureRandom.uuid) }
      end
      Dir.chdir("#{path}/ansible") do
        system('git submodule add git@github.com:rjayroach/ansible-roles.git roles')
      end
    end

    # NOTE: The remote project repository will *not* be destroyed
    def destroy_project
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
