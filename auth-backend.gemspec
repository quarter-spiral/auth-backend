# -*- encoding: utf-8 -*-
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'auth-backend/version'

Gem::Specification.new do |gem|
  gem.name          = "auth-backend"
  gem.version       = Auth::Backend::VERSION
  gem.authors       = ["Thorben Schröder"]
  gem.email         = ["thorben@quarterspiral.com"]
  gem.description   = %q{Authentication backend coming with OAUTH2 and a tiny administration panel}
  gem.summary       = %q{Authentication backend}
  gem.homepage      = ""

  gem.files         = `git ls-files`.split($/)
  gem.executables   = gem.files.grep(%r{^bin/}).map{ |f| File.basename(f) }
  gem.test_files    = gem.files.grep(%r{^(test|spec|features)/})
  gem.require_paths = ["lib"]

  gem.add_dependency 'rack', '~> 1.4.5'
  gem.add_dependency 'sinatra'
  gem.add_dependency 'sinatra-flash'
  gem.add_dependency 'bcrypt-ruby', '~> 3.0.0'
  gem.add_dependency 'activerecord', '>= 3.2.13'
  gem.add_dependency 'sinatra-activerecord'
  gem.add_dependency 'uuid'
  gem.add_dependency 'json', '~> 1.7.7'
  gem.add_dependency 'kaminari'
  gem.add_dependency 'padrino-helpers', '>= 0.11.2'
  gem.add_dependency 'graph-client', '~> 0.0.13'

  gem.add_dependency 'unicorn'
  gem.add_dependency 'newrelic_rpm'
  gem.add_dependency 'ping-middleware', '~> 0.0.2'
  gem.add_dependency 'omniauth', '~> 1.1.1'
  gem.add_dependency 'omniauth-facebook', '~> 1.4.1'
  gem.add_dependency 'firebase_token_generator'
  gem.add_dependency 'futuroscope', '>= 0.1.3'
  gem.add_dependency 'facebook-client', '>= 0.0.5'
  gem.add_dependency 'playercenter-client', '0.0.5'
end
