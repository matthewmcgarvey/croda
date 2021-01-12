require "./src/croda"

class MyPlugin
  module RequestMethods
    def foo
      puts "FOO"
    end
  end

  module RequestClassMethods
    def bar
      puts "BAR"
    end
  end
end

class App < Croda::App
  plugin MyPlugin

  route do |r|
    puts r.path
    puts r.foo
    puts r.class.bar
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
puts "App running on http://127.0.0.1:8080"
server.listen
