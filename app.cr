require "./src/croda"

class App < Croda::App
  route do |r|
    puts r.request.path
  end
end

server = HTTP::Server.new([
  HTTP::ErrorHandler.new,
  HTTP::LogHandler.new,
  HTTP::CompressHandler.new,
  App.new,
  HTTP::StaticFileHandler.new("."),
])

server.bind_tcp "127.0.0.1", 8080
server.listen
