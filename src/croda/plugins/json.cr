require "json"

abstract class Croda
  module CrodaPlugins
    module Json
      module InstanceMethods
        def json(obj)
          response.headers["Content-Type"] = "application/json"
          obj.to_json
        end
      end
    end

    register_plugin :json, Croda::CrodaPlugins::Json
  end
end
