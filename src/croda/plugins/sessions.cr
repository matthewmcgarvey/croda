require "base64"
require "json"

abstract class Croda
  module CrodaPlugins
    module Sessions
      SESSIONS_KEY = "croda.session"

      module InstanceMethods
        def session : Hash(String, String)
          request.session
        end

        def clear_session
          session.clear
        end

        macro included
          after_hook 50 do
            request.persist_session(response, session)
          end
        end
      end

      module RequestMethods
        @session : Hash(String, String)? = nil

        def session : Hash(String, String)
          @session ||= load_session
        end

        def persist_session(response, session : Hash(String, String))
          response.set_cookie(SESSIONS_KEY, Base64.strict_encode(session.to_json))
        end

        private def load_session : Hash(String, String)
          session = Hash(String, String).new
          cookies[SESSIONS_KEY]?.try do |contents|
            raw_json = String.new(Base64.decode(contents.value))
            JSON.parse(raw_json).as_h.each do |key, value|
              session[key.to_s] = value.as_s
            end
          end
          session
        end
      end
    end

    register_plugin :sessions, Croda::CrodaPlugins::Sessions
  end
end
