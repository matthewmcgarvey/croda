require "croda"
require "db"
require "ecr"
require "sqlite3"

DATABASE = DB.open("sqlite3:./development.db")

class App < Croda
  plugin :json
  plugin :cookies
  plugin :sessions
  plugin :flash
  plugin :csrf
  plugin :named_routes
  plugin :named_routes

  route("foo") do |r|
    puts "in foo"
    r.get do
      "hey there!"
    end
  end

  route do |r|
    # check_csrf!

    r.root do
      todos = DATABASE.query_all("SELECT * FROM todos", as: {id: Int32, task: String, completed_at: Time?})
      pp flash.now
      ECR.render "src/templates/todos.ecr"
    end

    r.post "todos" do
      form = r.form
      task = form["task"]
      DATABASE.exec("INSERT INTO todos (task) VALUES (?)", task)
      flash["foo"] = "bar"
      r.redirect "/"
    end

    r.route("foo")
  end
end

server = HTTP::Server.new([
  Croda::Handler.new(App),
])
server.bind_tcp "127.0.0.1", 3000
puts "Server running on http://127.0.0.1:3000"
server.listen
