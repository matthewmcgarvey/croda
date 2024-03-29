require "../src/croda"
require "ecr"

class App < Croda
  plugin :json

  route do |r|
    r.on "users" do
      users = [
        {id: 1, name: "Tommy"},
      ]

      r.on "me" do
        r.is do
          "WOAH!"
        end
      end

      r.get "html" do
        ECR.render "examples/html.ecr"
      end

      r.is Int32 do |user_id|
        user = users.find { |user| user[:id] == user_id }
        if user.nil?
          response.status = 404
          next "No matching user"
        end

        json user
      end

      json users
    end
  end
end

server = HTTP::Server.new([
  Croda::Handler.new(App),
])
server.bind_tcp "127.0.0.1", 3000
puts "Server running on http://127.0.0.1:3000"
server.listen
