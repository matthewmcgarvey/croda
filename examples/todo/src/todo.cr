require "croda"
require "db"
require "sqlite3"

DATABASE = DB.open("sqlite3:./development.db")

class App < Croda
  plugin :render
  plugin :json
  plugin :request_body
  plugin :cookies
  plugin :sessions
  plugin :flash
  plugin :csrf

  route do |r|
    check_csrf!

    r.root do
      todos = DATABASE.query_all("SELECT * FROM todos", as: {id: Int32, task: String, completed_at: Time?})
      pp flash.now
      render "src/templates/todos.ecr"
    end

    r.post "todos" do
      form = r.form
      task = form["task"]
      DATABASE.exec("INSERT INTO todos (task) VALUES (?)", task)
      flash["foo"] = "bar"
      r.redirect "/"
    end
  end
end

server = HTTP::Server.new([
  App.new,
])
server.bind_tcp "127.0.0.1", 3000
puts "Server running on http://127.0.0.1:3000"
server.listen
