module Prepd
  def self.options=(options)
    @options = options
  end
  def self.options; @options; end

  def self.commands
    puts (methods(false) - %i(:options= :options :commands default_settings)).join("\n")
  end

  def self.new(name)
    Client.create(name: name)
  end
end
