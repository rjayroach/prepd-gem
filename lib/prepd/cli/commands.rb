require 'prepd/models/base'
require 'prepd/models/developer'
require 'prepd/models/machine'
require 'prepd/models/project'
require 'prepd/models/machine_project'

module Prepd
  def self.commands
    puts (methods(false) - %i(commands)).join("\n")
  end

  def self.install
    config.create_type = :developer
    new
  end

  def self.new(name = ARGV[0])
    obj = klass.create(name: name)
    return obj.errors.full_messages.join('. ') unless obj.persisted?
    nil
  end

  def self.ls
    klass.all.pluck(:name)
  end

  def self.show(name = nil)
    name ||= ARGV[0] || Dir.pwd.split('/').last
    return unless obj = klass.find_by(name: name)
    YAML.load(obj.to_yaml)
  end

  def self.rm(name = nil)
    name ||= ARGV[0] || Dir.pwd.split('/').last
    return unless obj= klass.find_by(name: name)
    obj.destroy
  end

  def self.klass
    Kernel.const_get("Prepd::#{config.create_type.capitalize}")
  end
end
