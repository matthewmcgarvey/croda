abstract class Croda::App
  include HTTP::Handler
  class_property routing_block : (Croda::Request ->)?

  def self.route(&block : Croda::Request ->)
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
    request = Croda::Request.new(context.request)
    with self yield request
  end

  macro extend_request(instance_methods_class, class_methods_class)
    {% if imc = instance_methods_class.resolve? %}
      class ::Croda::Request
        include {{ imc }}
      end
    {% end %}

    {% if cmc = class_methods_class.resolve? %}
      class ::Croda::Request
        extend {{ cmc }}
      end
    {% end %}
  end

  macro plugin(type)
    extend_request({{ "#{type}::RequestMethods".id }}, {{ "#{type}::RequestClassMethods".id }})
  end
end
