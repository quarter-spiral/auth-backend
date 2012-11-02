ENV['RACK_ENV'] ||= 'test'

Bundler.require

require 'minitest/autorun'
require 'nokogiri'

require 'auth-backend'

require 'rack/client'
include Auth::Backend

APP = App.new(test: true)
CLIENT = Rack::Client.new {run APP}
def CLIENT.get(url, headers = {}, body = '', &block)
  request('GET', url, headers, body, {}, &block)
end
def CLIENT.delete(url, headers = {}, body = '', &block)
  request('DELETE', url, headers, body, {}, &block)
end

def client
  @client ||= CLIENT
end

TEST_MOUNT = '/_tests_'

require 'auth-backend/test_helpers'
TEST_HELPERS = TestHelpers.new(APP)
