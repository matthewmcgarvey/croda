require "base64"
require "json"
require "openssl/cipher"

# You can run `openssl rand -base64 32` to generate a secret key.
# Never store the secret key in git or expose it.
# If the key is ever exposed, you must generate a new key, but you will lose all sessions
abstract class Croda
  module CrodaPlugins
    module Sessions
      DEFAULT_SESSION_KEY       = "croda.session"
      DEFAULT_ENCRYPTION_PREFIX = Base64.strict_encode("croda") + "--"
      DEFAULT_COOKIE_OPTIONS    = {path: "/", samesite: HTTP::Cookie::SameSite::Lax}
      CIPHER_ALGORITHM          = "aes-256-ctr"

      protected class_getter secret_key : String do
        raise "Croda::CrodaPlugins::Sessions requires `secret_key`"
      end
      protected class_getter session_key : String do
        raise "Croda::CrodaPlugins::Sessions requires `session_key`"
      end

      def self.configure(_app : Croda.class, secret_key : String, session_key : String = DEFAULT_SESSION_KEY)
        @@secret_key = secret_key
        @@session_key = session_key
      end

      module InstanceMethods
        def session : Hash(String, String)
          request.session
        end

        def clear_session
          session.clear
        end

        macro included
          require_plugin :sessions, :cookies

          # if the session was loaded, persist it onto the response
          after_hook 50 do
            if request.session_loaded?
              request.persist_session(response)
            end
          end
        end
      end

      module RequestMethods
        @session : Hash(String, String)? = nil

        def session : Hash(String, String)
          @session ||= sessions_load
        end

        def session_loaded? : Bool
          !!@session
        end

        def persist_session(response)
          response.set_cookie(Sessions.session_key, sessions_encrypt(session), **DEFAULT_COOKIE_OPTIONS)
        end

        private def sessions_load : Hash(String, String)
          session = Hash(String, String).new
          cookies[Sessions.session_key]?.try do |contents|
            raw_json = sessions_decrypt(contents.value)
            break if raw_json.nil?

            JSON.parse(raw_json).as_h.each do |key, value|
              session[key.to_s] = value.as_s
            end
          end
          session
        end

        private def sessions_decrypt(cookie_val : String) : String?
          return unless cookie_val.starts_with?(Sessions::DEFAULT_ENCRYPTION_PREFIX)

          cookie_val = cookie_val.lchop(Sessions::DEFAULT_ENCRYPTION_PREFIX)
          value = Base64.decode(cookie_val)
          cipher = OpenSSL::Cipher.new(Sessions::CIPHER_ALGORITHM)
          block_size = 16 # size of iv
          data = value[0, value.size - block_size]
          iv = value[value.size - block_size, block_size]
          cipher.decrypt
          cipher.key = Sessions.secret_key
          cipher.iv = iv
          # decrypt
          decrypted_data = IO::Memory.new
          decrypted_data.write(cipher.update(data))
          decrypted_data.write(cipher.final)
          String.new(decrypted_data.to_slice)
        end

        private def sessions_encrypt(session : Hash(String, String)) : String
          cipher = OpenSSL::Cipher.new(Sessions::CIPHER_ALGORITHM)
          cipher.encrypt
          cipher.key = Sessions.secret_key
          iv = cipher.random_iv
          # encrypt
          data = IO::Memory.new
          data.write(cipher.update(session.to_json.to_slice))
          data.write(cipher.final)
          data.write(iv)
          String.build do |value|
            value << Sessions::DEFAULT_ENCRYPTION_PREFIX
            value << Base64.strict_encode(data.to_slice)
          end
        end
      end
    end

    register_plugin :sessions, Croda::CrodaPlugins::Sessions
  end
end
