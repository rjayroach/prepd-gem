# Load configuration yaml
require 'yaml'
require 'erb'

# Apply deep_merge method to Hash class
class ::Hash
  def deep_merge(second)
    merger = proc { |key, v1, v2| Hash === v1 && Hash === v2 ? v1.merge(v2, &merger) : v2 }
    self.merge(second, &merger)
  end
end

module Prepd
  module Vagrant
    class Config
      # NOTE: paths a relative to the location of the Vagrantfile from which this file is included
      WORKSPACE_CONFIG_FILE = '../../prepd-workspace.yml'
      BASE_CLUSTER_CONFIG_FILE = '../vagrant.yml'
      CLUSTER_CONFIG_FILE = 'vagrant.yml'

      attr_accessor :workspace, :base, :cluster

      def workspace
        @workspace ||= YAML.load(ERB.new(File.read(WORKSPACE_CONFIG_FILE)).result(binding))
      end

      def base
        return @base if @base
        settings = {}
        config = YAML.load(ERB.new(File.read(BASE_CLUSTER_CONFIG_FILE)).result(binding))
        settings = config['settings']
        @base = YAML.load(ERB.new(File.read(BASE_CLUSTER_CONFIG_FILE)).result(binding))
      end

      def cluster
        return @cluster if @cluster
        settings = base['settings']
        boxes = base['boxes']
        config = YAML.load(ERB.new(File.read(CLUSTER_CONFIG_FILE)).result(binding))
        config['machines'].each do |k, v|
          config['machines'][k] = config['defaults'].deep_merge(v)
        end
        @cluster = config
      end

      def machines
        cluster['machines'].keys
      end

      def machine_config(key)
        cluster['machines'][key]
      end
    end

    class Machine
      attr_accessor :name, :config

      def initialize(name = 'node1')
        @name = name
      end

      def config
        @config ||= Config.new.machine_config(name)
      end

      def autostart
        config['vm']['autostart'] || false
      end
    
      def host_name
        "#{config['name'] || name}.#{config['domain']}"
      end

      def vm_box
        config['vm']['box']
      end

      def vm_box_url
        config['vm']['box_url']
      end

      def mounts
        config['mounts'] || {}
      end
      
      def port_forwards
        config['vm']['port_forwards'] || {}
      end

      def ssh_interface
        config['ssh']['interface']
      end
      
      def ansible_groups
        config['ansible_groups'] || {}
      end
    end
  end
end

# Testing
unless defined? PREPD_VAGRANT
  m = Prepd::Vagrant::Machine.new('node0')
  require 'pry'
  binding.pry
end
