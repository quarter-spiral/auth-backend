require_relative './spec_helper.rb'

require 'json'
require 'uri'

def must_redirect_to(path, response)
  response.status.must_equal 302
  URI.parse(response.headers['Location']).path.must_equal path
end
