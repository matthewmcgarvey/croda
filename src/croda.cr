require "http"
require "./croda/*"

abstract class Croda
  include HTTP::Handler
  include CrodaPlugins::Base::InstanceMethods
  plugin CrodaPlugins::Base
end
