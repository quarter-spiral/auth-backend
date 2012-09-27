ENV['RACK_ENV'] ||= 'test'

Bundler.require

require 'minitest/autorun'
require 'nokogiri'

require 'auth-backend'

Auth::Backend::Apps.setup!
