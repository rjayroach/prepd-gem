module Prepd
  def self.commands
    %i(ls new show rm)  # methods(false) - %i(commands)
  end

  def self.ls
    klass.all.pluck(:name)
  end

  def self.new(name = ARGV[0])
    # TODO: this should display the appropriate help if name is not supplied
    return 'Must supply APP_PATH' unless name
    obj = klass.create(name: name)
    obj.persisted? ? nil : obj.errors.full_messages.join('. ')
  end

  def self.show(name = nil)
    name ||= ARGV[0] || Dir.pwd.split('/').last
    return unless obj = klass.find_by(name: name)
    YAML.load(obj.to_yaml)
  end

  def self.rm(name = nil)
    name ||= ARGV[0] || Dir.pwd.split('/').last
    return unless obj = klass.find_by(name: name)
    obj.destroy
  end

  def self.klass
    Kernel.const_get("Prepd::#{config.create_type.capitalize}")
  end
end
