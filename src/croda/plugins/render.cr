require "kilt"

abstract class Croda
  module CrodaPlugins
    module Render
      module InstanceMethods
        macro render(template_path)
          Kilt.render {{ template_path }}
        end
      end
    end
  end
end
