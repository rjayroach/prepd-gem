module Prepd
  def self.commands
    puts (methods(false) - %i(commands)).join("\n")
  end

  def self.rm
    FileUtils.rm_rf(config_dir)
  end

  # TODO: Probe system for whether it is virutal or not and default accordingly
  # # hostnamectl status | grep Virtualization will return 0 when found (vm) and 1 when not (host)
  def self.create_new
    fail "You must supply APP_PATH" unless config.app_path
    fail "Path '#{config.app_path}' already exists!" if Dir.exists?(config.app_path)
    require "prepd/#{config.create_type}"
    obj = Kernel.const_get("Prepd::#{config.create_type.capitalize}").new
    FileUtils.mkdir_p(config.app_path)
    Dir.chdir(config.app_path) { STDOUT.puts obj.create }
    FileUtils.rm_rf(config.app_path) if config.no_op
  end
end
