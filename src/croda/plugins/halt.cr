module Croda::CrodaPlugins
  module Halt
    module RequestMethods
      def halt(status : Int32) : Nil
        @response.status = status
        halt
      end
    end
  end

  register_plugin :halt, Croda::CrodaPlugins::Halt
end
