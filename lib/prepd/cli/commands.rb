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

  def self.rm
    FileUtils.rm_rf(config_dir)
    FileUtils.rm_rf(data_dir)
  end

  def self.clients; Client.pluck(:name); end

  def self.projects; Project.pluck(:name); end

  def self.current_client
    @client
  end

  def self.current_client=(client)
    STDOUT.puts 'duh'
    @client = client
    Dir.chdir(client.path) do
      Pry.start(client, prompt: [proc { "prepd(#{client.name}) > " }])
    end
    STDOUT.puts 'duh2'
    nil
  end
end
