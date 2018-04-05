module Prepd
  class Base
    include ActiveModel::Model
    include ActiveModel::Validations::Callbacks
    extend ActiveModel::Callbacks

    define_model_callbacks :create

		def create
			run_callbacks :create do
				# Your create action methods here
			end
		end
  end
  
  module Component
    extend ActiveSupport::Concern

    included do
      attr_accessor :name

      validates :name, presence: true
      validate :component_directory_does_not_exist
    end

    def component_directory_does_not_exist
      return if Prepd.config.force
      errors.add(:directory_exists, component_dir) if Dir.exists?(component_dir)
    end

    def in_component_dir
      in_component_root do
        Dir.chdir(name) { yield }
      end
    end

    def component_dir
      "#{component_root}/#{name}"
    end

    def in_component_root(dir = self.class::WORK_DIR)
      in_workspace_root do
        Dir.chdir(dir) { yield }
      end
    end

    def component_root
      "#{workspace_root}/#{self.class::WORK_DIR}"
    end

    def in_workspace_root
      raise StandardError, 'Not a prepd workspace' if workspace_root.nil?
      Dir.chdir(workspace_root) { yield }
    end

    def workspace_root
      path = Pathname.new(Prepd.config.working_dir)
      until path.root?
        break path if File.exists?("#{path}/prepd-workspace.yml")
        path = path.parent
      end
    end

    def files_dir
      "#{Prepd.files_dir}/#{self.class::WORK_DIR}"
    end

    def klass_name
      binding.pry
      "#{Prepd.files_dir}/#{self.class::WORK_DIR}"
    end
  end
end

=begin
require 'yaml'
require 'erb'

module Prepd
  class Base < ActiveRecord::Base
    self.abstract_class = true

    attr_accessor :config

    after_initialize :set_config

    def set_config
      self.config = Prepd.config
    end

    def as_json(options = {})
      super(except: [:created_at, :updated_at])
    end

    def kind
      self.class.name.split('::').last.downcase
    end

    def to_yaml
      { 'kind' => kind, 'data' => for_yaml }.to_yaml
    end

    def from_yaml
      File.exists?(config_file_path) ? YAML.load_file(config_file_path) : {}
    end

    def write_config
      FileUtils.mkdir_p("#{config_dir}/vars") unless Dir.exists?("#{config_dir}/vars")
      File.open(config_file_path, 'w') { |f| f.write(to_yaml) }
    end

    def config_file_path
      "#{config_dir}/vars/setup.yml"
    end

    #
    # Remove the project from the file system
    #
    def delete_config_dir
      FileUtils.rm_rf(config_dir)
    end
  end
end
=end
