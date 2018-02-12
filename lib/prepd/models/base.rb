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
