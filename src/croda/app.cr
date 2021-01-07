abstract class Croda::App
  include HTTP::Handler
  class_property routing_block : (HTTP::Server::Context ->)?

  def self.route(&block : HTTP::Server::Context ->)
    self.routing_block = block
  end

  def call(context)
    if block = self.class.routing_block
      execute context, &block
      return
    end
    call_next(context)
  end

  def execute(context)
    with self yield context
  end
end
