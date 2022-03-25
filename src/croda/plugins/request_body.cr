require "mime"
require "uri"

abstract class Croda
  module CrodaPlugins
    module RequestBody
      module RequestMethods
        def raw_body : IO?
          @request.body
        end

        @body : Bool | String | Nil = false

        def body : String?
          temp = @body
          return temp unless temp.is_a?(Bool)

          @body = raw_body.try(&.gets_to_end)
        end

        @form : URI::Params?

        def form : URI::Params
          @form ||= URI::Params.parse(body.not_nil!)
        end
      end
    end

    register_plugin :request_body, Croda::CrodaPlugins::RequestBody
  end
end
