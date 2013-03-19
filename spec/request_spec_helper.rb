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
