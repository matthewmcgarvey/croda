abstract class Croda
  module CrodaPlugins
    module NamedRoutes
      module InstanceMethods
        CRODA_NAMED_ROUTE_PREVIOUS_DEF = [] of Nil

        macro route(name, &block)
          def handle_named_route(name : String)
            if name == {{ name.id.stringify }}
              _execute_named_route {{ block }}
            {% if !CRODA_NAMED_ROUTE_PREVIOUS_DEF.empty? %}
            else
              previous_def
            {% end %}
            end
          end
          {% CRODA_NAMED_ROUTE_PREVIOUS_DEF << nil %}
        end

        def _execute_named_route
          yield request
        end
      end

      module RequestMethods
        def route(name : String)
          @scope.handle_named_route(name)
        end
      end
    end

    register_plugin :named_routes, Croda::CrodaPlugins::NamedRoutes
  end
end
