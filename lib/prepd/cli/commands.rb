module Prepd
  class Command
    def self.config; Prepd.config; end

    def self.list(type = ARGV.shift)
      return 'invalid type' unless %w(clusters projects machines).include? type
      "Prepd::#{type.classify}".constantize.new.in_component_root { Dir.glob('*') }
    end

    def self.new(type = ARGV.shift, name = ARGV.shift, *args)
      cr = Creator.new(type: type)
      # TODO: this should display the appropriate help if name is not supplied
      return cr.errors.full_messages.join("\n") unless cr.valid?
      # return 'Must supply type' unless type
      # return 'Must supply APP_PATH' unless name
      obj = cr.klass.new(name: name)
      return obj.errors.full_messages.join("\n") unless obj.valid?
      obj.create
      nil
    end

    def self.build(name = ARGV.shift)
      cr = Machine.new(name: name)
      return cr.errors.full_messages.join("\n") unless cr.valid?
      cr.create
      nil
    end

    def self.show(name = nil)
      name ||= ARGV[0] || Dir.pwd.split('/').last
      return unless obj = klass.find_by(name: name)
      YAML.load(obj.to_yaml)
    end

    def self.up(name = ARGV.shift)
      Cluster.new(name: name).up
    end

    def self.rm(name = nil)
      name ||= ARGV[0] || Dir.pwd.split('/').last
      return unless obj = klass.find_by(name: name)
      obj.destroy ? nil : obj.errors.full_messages.join('. ')
    end

    #
    # Clone Ansible roles
    #
    # TODO: Externalize these values to a yaml file
    ANSIBLE_ROLES_PATH = "#{Dir.home}/.ansible/roles".freeze
    ANSIBLE_ROLES = {'prepd-roles' => 'prepd', 'terraplate' => 'terraplate', 'terraplate-components' => 'terraplate-components' }.freeze

    # TODO: for a mac, install xcode, brew, python, pip, ansible, etc
    def self.configure_host
      FileUtils.mkdir_p(ANSIBLE_ROLES_PATH) unless Dir.exists? ANSIBLE_ROLES_PATH
      Dir.chdir(ANSIBLE_ROLES_PATH) do
        ANSIBLE_ROLES.each do |key, value|
          next if Dir.exists? "#{ANSIBLE_ROLES_PATH}/#{value}"
          system("git clone #{Prepd.git_log} git@github.com:rjayroach/#{key} #{value}")
        end
      end
    end
  end

  class Creator
    include ActiveModel::Model
    include ActiveModel::Validations::Callbacks
    VALID_CLASSES = %w(workspace cluster project).freeze

    attr_accessor :type

    validates :type, presence: true, inclusion: { in: VALID_CLASSES }

    before_validation :set_type_down

    def set_type_down
      self.type = self.type.downcase
    end

    def klass
      Kernel.const_get("Prepd::#{type.capitalize}")
    end
  end
end
