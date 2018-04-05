require 'yaml'
require 'erb'
require 'json'

module Prepd
  class Machine < Base
    WORK_DIR = 'machines'
    USER_CONFIG_FILE = 'build.yml'
    VALID_BUMP_NAMES = %w(major minor patch)

    include Prepd::Component

    attr_accessor :bump

    before_validation :set_defaults

    validates :bump, inclusion: { in: VALID_BUMP_NAMES, message: "must be one of #{VALID_BUMP_NAMES.join(', ')}" }
    validate :name_included_in_yaml

    after_create :perform

    def set_defaults
      self.bump ||= Prepd.config.bump || 'patch'
    end

    def name_included_in_yaml
      return if valid_build_names.include? name
      errors.add(:invalid_name, "valid names are #{valid_build_names.join(', ')}")
    end

    def valid_build_names
      yml['images'].keys
    end

    def yml
      return @yml if @yml
      in_component_root do
        @yml = YAML.load(ERB.new(File.read("#{workspace_root}/prepd-workspace.yml")).result(binding)).merge(
          YAML.load(ERB.new(File.read("#{component_root}/#{USER_CONFIG_FILE}")).result(binding)))
      end
    end

    #
    # Execute the builder
    #
    def perform
      # return "#{build_action}\n#{build_env}" if Prepd.config.no_op
      in_component_root do
        # binding.pry
        # FileUtils.cp("#{Prepd.files_dir}/machine/#{os_env['base_dir']}/preseed.cfg", '.')
        system(build_env, "packer build #{action_file}")
        # FileUtils.rm('preseed.cfg')
      end
    end

    def action_file
      return "#{Prepd.files_dir}/machine/#{build_action}.json" unless build_action.eql?(:iso)
      "#{Prepd.files_dir}/machine/#{os_env['base_dir']}/iso.json"
    end

    def build
      yml['images'][name]
    end

    # Get references to current build, the os build and the os env
    def os_build
      os_build = build
      loop do
        break if os_build['source'].has_key?('os_image')
        os_build = yml['images'][os_build['source']['image']]
      end
      os_build
    end

    def os_env
      yml['os_images'][os_build['source']['os_image']]
    end

    #
    # Derive values for image and box
    #
    def base_dir; os_env['base_dir'] end
    # def build_image_dir; "#{yml['name']}/images/#{name}" end
    def build_image_dir; "images/#{name}" end
    def build_image_name; "#{os_env['base_name']}-#{name}" end
    # def build_box_dir; "#{Dir.pwd}/#{yml['name']}/boxes" end
    def build_box_dir; "#{Dir.pwd}/boxes" end
    def box_json_file; "#{build_box_dir}/#{build_image_name}.json" end

    #
    # Caclulate the packer builder to run: :iso, :build, :rebuild or :push
    #
    def build_action
      return :push if Prepd.config.push
      return :rebuild if File.exists?("#{build_image_dir}/#{build_image_name}-disk1.vmdk")
      build['source'].has_key?('os_image') ? :iso : :build
    end

    #
    # Setup env vars for the builder
    #
    def build_env
      xbuild_env = {
        'VM_BASE_NAME' => os_env['base_name'],
        'VM_INPUT' => build_action.eql?(:build) ? build['source']['image'] : name,
        'VM_OUTPUT' => name,
        'BOX_NAMESPACE' => yml['name'],
        'BOX_VERSION' => box_version,
        'PLAYBOOK_FILE' => build['provisioner'],
        'JSON_RB_FILE' => "#{Prepd.files_dir}/machine/json.rb"
      }

      xbuild_env.merge!({
        'ISO_CHECKSUM' => os_env['iso_checksum'],
        'ISO_URL' => os_env['iso_url']
      }) if build_action.eql?(:iso)

      xbuild_env.merge!({
        'AWS_PROFILE' => yml['aws']['profile'],
        'S3_BUCKET' => yml['aws']['s3_bucket'],
        'S3_REGION' => yml['aws']['s3_region'],
        'S3_BOX_DIR' => "#{yml['aws']['box_dir']}/#{yml['namesapce']}"
      }) if build_action.eql?(:push)
      xbuild_env
    end

    # Calculate the next box version
    def box_version
      return '0.0.1' unless File.exists?(box_json_file)
      json = JSON.parse(File.read(box_json_file))
      current_version = json['versions'].first['version']
      return current_version if build_action.eql?(:push)
      inc(current_version, type: bump)
    end

    def inc(version, type: 'patch')
      idx = { 'major' => 0, 'minor' => 1, 'patch' => 2 }
      ver = version.split('.')
      ver[idx['patch']] = 0 if %w(major minor).include? type
      ver[idx['minor']] = 0 if %w(major).include? type
      ver[idx[type]] = ver[idx[type]].to_i + 1
      ver.join('.')
    end
  end
end
