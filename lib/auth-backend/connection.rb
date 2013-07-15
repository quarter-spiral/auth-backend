module Auth::Backend
  class Connection
    attr_reader :graph, :playercenter

    def self.create(graph_backend_url = nil)
      new(
        graph_backend_url || ENV['QS_GRAPH_BACKEND_URL'] || 'http://graph-backend.dev',
        ENV['QS_PLAYERCENTER_BACKEND_URL'] || 'http://playercenter-backend.dev'
      )
    end

    def initialize(graph_backend_url, playercenter_backend_url)
      @graph = ::Graph::Client.new(graph_backend_url)
      @playercenter = ::Playercenter::Client.new(playercenter_backend_url)
    end
  end
end
