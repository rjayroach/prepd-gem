# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'prepd/version'

Gem::Specification.new do |spec|
  spec.name          = 'prepd'
  spec.version       = Prepd::VERSION
  spec.authors       = ['Robert Roach']
  spec.email         = ['rjayroach@gmail.com']

  spec.summary       = %q{An easy to use tool to create Production Ready Environments for Project Development}
  spec.description   = %q{Prepd assists builders of web application products to start with the end in mind by making it easy to stand up all required infrastructure
  *before* starting to code the application}
  spec.homepage      = 'https://github.com/rjayroach/prepd-gem'
  spec.license       = 'MIT'

  spec.files         = `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features|docs)/}) }
  spec.bindir        = 'exe'
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ['lib']

  spec.add_development_dependency 'bundler', '~> 1.12'
  spec.add_development_dependency 'rake', '~> 12.0'

  spec.add_dependency 'dotenv'
  spec.add_dependency 'pry'
  spec.add_dependency 'activerecord'
  spec.add_dependency 'sqlite3'
  spec.add_dependency 'awesome_print'
end
