#!/usr/bin/env ruby
require 'json'

# path, prefix, name, version = ARGV
prefix, name, version = ARGV
path = "#{Dir.pwd}/boxes"
# prefix = 'prepd'
# name = 'debian-stretch-amd64-developer'
# version = '9.9.9'

json = {
  name: "#{prefix}/#{name}",
  versions: [
    {
      version: version,
      providers: [
        {
          name: 'virtualbox',
          url: "file://#{path}/#{name}.box"
        }
      ]
    }
  ]
}

File.open("#{path}/#{name}.json", 'w') { |f| f.write json.to_json }
