ENV['RACK_ENV'] ||= 'test'

Bundler.require

require 'minitest/autorun'
require 'nokogiri'

require 'auth-backend'

require 'graph-backend'

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

module Auth
  class Client
    alias raw_initialize initialize
    def initialize(url, options = {})
      raw_initialize(url, options.merge(adapter: [:rack, APP]))
    end
  end
end

GRAPH_BACKEND = Graph::Backend::API.new
module Auth::Backend
  class Connection
    alias raw_initialize initialize
    def initialize(*args)
      result = raw_initialize(*args)

      graph_adapter = Service::Client::Adapter::Faraday.new(adapter: [:rack, GRAPH_BACKEND])
      @graph.client.raw.adapter = graph_adapter

      result
    end
  end
end

# Wipe the graph
connection = Graph::Backend::Connection.create.neo4j
(connection.find_node_auto_index('uuid:*') || []).each do |node|
  connection.delete_node!(node)
end
