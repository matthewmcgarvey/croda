abstract class Croda
  module CrodaPlugins
    # this is a deprecated plugin for Roda
    # but the implementation of RouteCsrf is way more complicated
    # I'm not going to be implementing Roda's anyways since it delegates to Rack
    # I'll be using Lucky's implementation instead
    module Csrf
      module InstanceMethods
        CSRF_FIELD   = "_csrf"
        CSRF_HEADER  = "X-CSRF-Token"
        CSRF_METHODS = %w(POST DELETE PATCH PUT)

        macro included
          # depend on request body parsing to get the CSRF field from the form submission
          plugin :request_body
        end

        def check_csrf!
          return unless CSRF_METHODS.includes?(request.method)

          user_provided_token = request.headers[CSRF_HEADER]? || request.form[CSRF_FIELD]?
          return if csrf_token == user_provided_token

          response.status = 403
          response.headers["Content-Type"] = "text/html"
          response.headers["Content-Length"] = "0"
          throw :halt
        end

        def csrf_field : String
          "<input type=\"hidden\" name=\"#{CSRF_FIELD}\" value=\"#{csrf_token}\" />"
        end

        def csrf_token : String
          session[CSRF_HEADER] ||= Random::Secure.urlsafe_base64(32)
        end
      end
    end

    register_plugin :csrf, Croda::CrodaPlugins::Csrf
  end
end
