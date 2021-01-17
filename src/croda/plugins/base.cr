class Croda
  module CrodaPlugins
    module Base
      module ClassMethods
        macro extended
          @@route_block : (Croda::CrodaRequest ->)?
        end

        def route(&block : Croda::CrodaRequest ->)
          @@route_block = block
        end
      end

      module InstanceMethods
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

        def call(context)
          if block = @@route_block
            execute context, &block
            return
          end
          call_next(context)
        end

        def execute(context)
          request = Croda::CrodaRequest.new(context.request, self)
          catch :halt do
            with self yield request
          end
        end
      end

      module RequestMethods
        def initialize(@request : HTTP::Request, @app : ::Croda)
        end

        def get
          if get?
            with @app yield
            throw :halt
          end
        end

        def get(path)
          if get? && path_matches?(path)
            with @app yield
            throw :halt
          end
        end

        def post
          if post?
            with @app yield
            throw :halt
          end
        end

        private def get?
          request_method == "GET"
        end

        private def post?
          request_method == "POST"
        end

        private def path_matches?(path)
          @request.path == path
        end

        private def request_method
          @request.method.upcase
        end
      end
    end
  end
end
