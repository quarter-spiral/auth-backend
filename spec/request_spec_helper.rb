require_relative './spec_helper.rb'

require 'json'
require 'uri'

def must_redirect_to(path, response)
  response.status.must_equal 302
  expectation = URI.parse(path)
  result = URI.parse(response.headers['Location'].gsub(/^http:\/\/:\//, 'http:///'))

  result.host.must_equal expectation.host if expectation.host
  result.query.must_equal expectation.query if expectation.query

  result.path.must_equal expectation.path
end


AUTH_HELPERS = Auth::Backend::TestHelpers.new(APP)
OAUTH_APP = AUTH_HELPERS.create_app!
ENV['QS_OAUTH_CLIENT_ID'] = OAUTH_APP[:id]
ENV['QS_OAUTH_CLIENT_SECRET'] = OAUTH_APP[:secret]

USER_TOKEN = AUTH_HELPERS.get_token

def get_app_token
  app = AUTH_HELPERS.create_app!
  AUTH_HELPERS.get_app_token(app[:id], app[:secret])
end