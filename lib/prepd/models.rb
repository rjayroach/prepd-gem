module Prepd
  class Client < ActiveRecord::Base
    attr_accessor :data_dir
    has_many :projects
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
    has_many :applications

    validates :name, presence: true, uniqueness: { scope: :client }

    after_create :setup, unless: "mode.eql?('test')"
    after_create :setup_test, if: "mode.eql?('test')"

    #
    # Copy files from the prepd/files directory
    #
    def setup
      FileUtils.cp_r(files_path, path)
    end

    def setup_test
      FileUtils.mkdir_p(path)
      Dir.chdir(path) do
        %w(Vagrantfile bootstrap.sh).each do |link|
          FileUtils.ln_s("#{files_path}/#{link}", link)
        end
      end
    end

    def files_path
      "#{__dir__.split('/').reverse.drop(2).reverse.join('/')}/files"
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
      FileUtils.mkdir_p(path)
    end

    def path
     "#{project.path}/ansible/#{name}"
    end
  end
end
