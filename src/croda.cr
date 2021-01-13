require "http"
require "./croda/*"

abstract class Croda
  include HTTP::Handler

  macro croda_plugin(instance_methods_class, class_methods_class)
    {% if imc = instance_methods_class.resolve? %}
      include {{ imc }}
    {% end %}

    {% if cmc = class_methods_class.resolve? %}
      extend {{ cmc }}
    {% end %}
  end

  macro request_plugin(instance_methods_class, class_methods_class)
    {% if imc = instance_methods_class.resolve? %}
      class ::Croda::CrodaRequest
        include {{ imc }}
      end
    {% end %}

    {% if cmc = class_methods_class.resolve? %}
      class ::Croda::CrodaRequest
        extend {{ cmc }}
      end
    {% end %}
  end

  macro response_plugin(instance_methods_class, class_methods_class)
    {% if imc = instance_methods_class.resolve? %}
      class ::Croda::CrodaResponse
        include {{ imc }}
      end
    {% end %}

    {% if cmc = class_methods_class.resolve? %}
      class ::Croda::CrodaResponse
        extend {{ cmc }}
      end
    {% end %}
  end

  macro plugin(type)
    croda_plugin({{ "#{type}::InstanceMethods".id }}, {{ "#{type}::ClassMethods".id }})
    request_plugin({{ "#{type}::RequestMethods".id }}, {{ "#{type}::RequestClassMethods".id }})
    response_plugin({{ "#{type}::ResponseMethods".id }}, {{ "#{type}::ResponseClassMethods".id }})
  end

  plugin CrodaPlugins::Base
end
