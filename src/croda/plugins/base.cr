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
        def call(context)
          if block = @@route_block
            execute context, &block
            return
          end
          call_next(context)
        end

        def execute(context)
          request = Croda::CrodaRequest.new(context.request)
          with self yield request
        end
      end

      module RequestMethods
        def initialize(@request : HTTP::Request)
        end

        forward_missing_to @request
      end
    end
  end
end
