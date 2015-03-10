lib = File.expand_path('../lib/', __FILE__)
$:.unshift lib unless $:.include?(lib)

require 'rack-cas/version'

spec = Gem::Specification.new do |s|
  s.name = 'rack-cas'
  s.version = RackCAS::VERSION
  s.summary = 'Rack-based CAS client'
  s.description = 'Simple CAS authentication for Rails, Sinatra or any Rack-based site'
  s.files = Dir['README.*', 'MIT-LICENSE', 'lib/**/*.rb', 'lib/tasks/*.rake']
  s.require_path = 'lib'
  s.author = 'Adam Crownoble'
  s.email = 'adam.crownoble@biola.edu'
  s.homepage = 'https://github.com/biola/rack-cas'
  s.license = 'MIT'
  s.add_dependency 'rack', '~> 1.3'
  s.add_dependency 'addressable', '~> 2.3'
  s.add_dependency 'nokogiri', '~> 1.5'
  s.add_development_dependency 'rspec', '~> 3.2'
  s.add_development_dependency 'rspec-its', '~> 1.0'
  s.add_development_dependency 'rack-test', '~> 0.6'
  s.add_development_dependency 'webmock', '~> 1.6'
end
