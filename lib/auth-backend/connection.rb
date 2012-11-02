module Auth::Backend
  class Connection
    attr_reader :graph

    def self.create(graph_backend_url)
      new(graph_backend_url || 'http://graph-backend.dev')
    end

    def initialize(graph_backend_url)
      @graph = ::Graph::Client.new(graph_backend_url)
    end
  end
end
