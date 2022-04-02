abstract class Croda
  module CrodaPlugins
    module Flash
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
        FLASH_KEY = "_flash"

        macro included
          require_plugin :flash, :sessions

          after_hook 40 do
            if f = @flash
              next_flashes = f.nexts
              if next_flashes.empty?
                session.delete(FLASH_KEY)
              else
                session[FLASH_KEY] = next_flashes.to_json
              end
            end
          end
        end

        @flash : FlashStore? = nil

        def flash : FlashStore
          @flash ||= load_flash
        end

        private def load_flash : FlashStore
          hash = if raw_flash = session[FLASH_KEY]?
                   Hash(String, String).from_json(raw_flash)
                 else
                   Hash(String, String).new
                 end
          FlashStore.new(hash)
        end
      end
    end

    register_plugin :flash, Croda::CrodaPlugins::Flash
  end
end
