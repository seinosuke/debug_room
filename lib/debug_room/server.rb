module DebugRoom
  class Server
    extend Forwardable
    def_delegators :@server, :close

    attr_reader :server

    def initialize(main_screen)
      @main_screen = main_screen
      @server = TCPServer.open(PORT)
    end

    # TCPサーバを開始する
    def tcp_thread
      Thread.new do
        begin
          Timeout.timeout(5) do
            socket = @server.accept
            while buf = socket.gets
              @main_screen.add_message(buf)
            end
            socket.close
          end

        rescue Timeout::Error
          break if @main_screen.exit
          retry
        end while true
      end
    end
  end
end
