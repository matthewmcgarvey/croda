abstract class Croda
  module CrodaPlugins
    module Cookies
      module RequestMethods
        def cookies : HTTP::Cookies
          HTTP::Cookies.from_client_headers(headers)
        end
      end

      module ResponseMethods
        def delete_cookie(key, **values)
          set_cookie(key, {
            value:   "",
            path:    nil,
            domain:  nil,
            max_age: 0.seconds,
            expires: 1.year.ago,
          }.merge(values))
        end

        def set_cookie(key, value : String)
          set_cookie(key, {value: value})
        end

        private def set_cookie(key, values : NamedTuple)
          cookie = HTTP::Cookie.new(
            **values,
            name: key.to_s,
            http_only: true
          )
          cookies = HTTP::Cookies.from_server_headers(headers)
          cookies << cookie
          cookies.add_response_headers(headers)
        end
      end
    end

    register_plugin :cookies, Croda::CrodaPlugins::Cookies
  end
end
