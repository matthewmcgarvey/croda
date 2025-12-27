abstract class Croda
  module CrodaPlugins
    module Cookies
      protected class_getter domain : String?
      protected class_getter path : String?

      def self.configure(_app : Croda.class, domain : String? = nil, path : String? = nil)
        @@domain = domain
        @@path = path
      end

      module RequestMethods
        def cookies : HTTP::Cookies
          HTTP::Cookies.from_client_headers(headers)
        end
      end

      module ResponseMethods
        def delete_cookie(key : String, **values) : Nil
          set_cookie(key, {
            value:   "",
            path:    nil,
            domain:  nil,
            max_age: 0.seconds,
            expires: 1.year.ago,
          }.merge(values))
        end

        def set_cookie(key : String, value : String, **attrs) : Nil
          cookie_attrs = default_cookie_opts.merge(attrs)
          cookie = HTTP::Cookie.new(
            **cookie_attrs,
            name: key,
            value: value,
            http_only: true
          )
          cookies = HTTP::Cookies.from_server_headers(headers)
          cookies << cookie
          cookies.add_response_headers(headers)
        end

        private def default_cookie_opts : NamedTuple(domain: String?, path: String?)
          {domain: Cookies.domain, path: Cookies.path}
        end
      end
    end

    register_plugin :cookies, Croda::CrodaPlugins::Cookies
  end
end
