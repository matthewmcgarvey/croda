abstract class Croda
  module CrodaPlugins
    module Flash
      FLASH_KEY = "_flash"

      class FlashStore
        getter now : Hash(String, String)
        getter nexts = Hash(String, String).new

        def initialize(@now)
        end

        def []=(key : String, value : String)
          nexts[key] = value
        end

        def [](key : String) : String
          now[key]
        end

        def []?(key : String) : String?
          now[key]?
        end

        def keep
          nexts.merge!(now)
        end

        def clear
          now.clear
          nexts.clear
        end
      end

      module InstanceMethods
        macro included
          after_hook 40 do
            if f = request.flash
              next_flashes = f.nexts
              if next_flashes.empty?
                session.delete(Croda::CrodaPlugins::Flash::FLASH_KEY)
              else
                session[Croda::CrodaPlugins::Flash::FLASH_KEY] = next_flashes.to_json
              end
            end
          end
        end

        def flash : FlashStore
          request.flash || request.load_flash
        end
      end

      module RequestMethods
        protected getter flash : FlashStore? = nil

        protected def load_flash : FlashStore
          hash = if raw_flash = session[Croda::CrodaPlugins::Flash::FLASH_KEY]?
                   Hash(String, String).from_json(raw_flash)
                 else
                   Hash(String, String).new
                 end
          @flash = FlashStore.new(hash)
        end
      end
    end

    register_plugin :flash, Croda::CrodaPlugins::Flash
  end
end
