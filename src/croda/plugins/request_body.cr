require "mime"
require "uri"

abstract class Croda
  module CrodaPlugins
    module RequestBody
      module RequestMethods
        def raw_body : IO?
          @request.body
        end

        def body : String?
          raw_body.try(&.gets_to_end)
        end

        def form : URI::Params
          URI::Params.parse(body.not_nil!)
        end
      end
    end

    register_plugin :request_body, Croda::CrodaPlugins::RequestBody
  end
end
