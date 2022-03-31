require "http"
require "./ext/throw_catch"
require "./croda/*"

abstract class Croda
  include CrodaPlugins::Base::InstanceMethods
  plugin CrodaPlugins::Base
end
