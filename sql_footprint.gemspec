# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'sql_footprint/version'

Gem::Specification.new do |spec|
  spec.name          = 'sql_footprint'
  spec.version       = SqlFootprint::VERSION
  spec.authors       = ['Brandon Joyce', 'Michael Gee', 'Derek Schneider']
  spec.email         = [
    'brandon@sonerdy.com',
    'michaelpgee@gmail.com',
    'dschneider@covermymeds.com'
  ]

  spec.summary       = 'Keeps your DBA happy.'
  spec.description   = 'Check your footprint file into source control'
  spec.homepage      = 'https://github.com/covermymeds/sql_footprint'

  spec.files         = `git ls-files -z`.split("\x0").reject do |f|
    f.match(%r{^(test|spec|features)/})
  end
  spec.bindir        = 'exe'
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ['lib']

  # ruby version 2 uses older active record
  spec.add_dependency 'activerecord', '~> 4.2.10'
  spec.add_dependency 'activesupport', '~> 4.2.10'

  spec.add_development_dependency 'bundler', '~> 1.7'
  spec.add_development_dependency 'rake', '~> 10.0'
  spec.add_development_dependency 'rspec', '~> 3.5.0'
  spec.add_development_dependency 'pry'
  spec.add_development_dependency 'sqlite3'
  spec.add_development_dependency 'rubocop', '~> 0.39.0'
  spec.add_development_dependency 'rubocop-rspec', '~> 1.4.1'
end
