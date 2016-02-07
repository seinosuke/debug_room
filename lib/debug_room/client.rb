module DebugRoom
  class Client
    def send_message(message = "")
      socket = TCPSocket.open(HOST, PORT)
      socket.write(message)
      socket.close
    end
  end
end
