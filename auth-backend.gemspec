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

  gem.add_dependency 'sinatra'
  gem.add_dependency 'sinatra-flash'
  gem.add_dependency 'bcrypt-ruby'
  gem.add_dependency 'activerecord'
  gem.add_dependency 'sinatra-activerecord'
  gem.add_dependency 'uuid'
  gem.add_dependency 'pg'
  gem.add_dependency 'json'
  gem.add_dependency 'kaminari'
  gem.add_dependency 'padrino-helpers'
end
