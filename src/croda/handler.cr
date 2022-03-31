class Croda::Handler
  include HTTP::Handler

  def initialize(@app : Croda.class)
  end

  def call(context : HTTP::Server::Context)
    @app.execute(context)
  end
end
