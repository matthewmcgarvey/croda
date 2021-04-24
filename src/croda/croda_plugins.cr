abstract class Croda
  module CrodaPlugins
    REGISTERED_PLUGINS = {} of Nil => Nil

    macro register_plugin(name, mod)
      {% REGISTERED_PLUGINS[name] = mod %}
    end
  end
end

require "./plugins/*"
