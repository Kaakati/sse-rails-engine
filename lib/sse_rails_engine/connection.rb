module SseRailsEngine
  class Connection
    attr_accessor :stream

    SSE_HEADER = ["HTTP/1.1 200 OK\r\n",
                  "Content-Type: text/event-stream\r\n",
                  "Cache-Control: no-cache, no-store\r\n",
                  "Connection: close\r\n",
                  "\r\n"].join.freeze

    def initialize(io, env)
      @socket = io
      @socket.write SSE_HEADER
      @socket.flush
      @stream = ActionController::Live::SSE.new(io)
      @channels = requested_channels(env)
    end

    def write(name, data)
      return if filtered?(name)
      @stream.write(data, event: name)
      @socket.flush
    end

    private

    def filtered?(channel)
      return false if @channels.empty? || channel == Manager::HEARTBEAT_EVENT
      !@channels.include? channel
    end

    def requested_channels(env)
      Rack::Utils.parse_query(env["QUERY_STRING"]).fetch('channels', []).split(',').flatten
    end
  end
end
