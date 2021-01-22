abstract class Croda
  module CrodaPlugins
    module Base
      module InstanceMethods
        macro croda_plugin(instance_methods_class, class_methods_class)
          {% if imc = instance_methods_class.resolve? %}
            include {{ imc }}
          {% end %}
      
          {% if cmc = class_methods_class.resolve? %}
            extend {{ cmc }}
          {% end %}
        end

        macro request_plugin(instance_methods_class, class_methods_class)
          {% if imc = instance_methods_class.resolve? %}
            class ::Croda::CrodaRequest
              include {{ imc }}
            end
          {% end %}
      
          {% if cmc = class_methods_class.resolve? %}
            class ::Croda::CrodaRequest
              extend {{ cmc }}
            end
          {% end %}
        end

        macro response_plugin(instance_methods_class, class_methods_class)
          {% if imc = instance_methods_class.resolve? %}
            class ::Croda::CrodaResponse
              include {{ imc }}
            end
          {% end %}
      
          {% if cmc = class_methods_class.resolve? %}
            class ::Croda::CrodaResponse
              extend {{ cmc }}
            end
          {% end %}
        end

        macro plugin(type)
          croda_plugin({{ "#{type}::InstanceMethods".id }}, {{ "#{type}::ClassMethods".id }})
          request_plugin({{ "#{type}::RequestMethods".id }}, {{ "#{type}::RequestClassMethods".id }})
          response_plugin({{ "#{type}::ResponseMethods".id }}, {{ "#{type}::ResponseClassMethods".id }})
        end

        macro route(&block)
          def call(context)
            execute(context) {{ block }}
          end
        end

        @response : Croda::CrodaResponse?

        def execute(context)
          response = @response = Croda::CrodaResponse.new(context.response)
          request = Croda::CrodaRequest.new(context.request, response)
          catch :halt do
            yield request
          end
          response.finish
          @response = nil
        end

        def response : Croda::CrodaResponse
          @response.not_nil!
        end
      end

      module RequestMethods
        @request : HTTP::Request
        @response : Croda::CrodaResponse
        property remaining_path : String

        def initialize(@request : HTTP::Request, @response : Croda::CrodaResponse)
          @remaining_path = @request.path
        end

        def on : Nil
          block_result(yield)
          throw :halt
        end

        def on(arg) : Nil
          path = @remaining_path

          if result = match(arg)
            block_result(yield *result)
            throw :halt
          else
            @remaining_path = path
            false
          end
        end

        def is : Nil
          return if empty_path?

          block_result(yield)
          throw :halt
        end

        def is(arg) : Nil
          path = @remaining_path

          if (result = match(arg)) && empty_path?
            block_result(yield *result)
            throw :halt
          else
            @remaining_path = path
            false
          end
        end

        def root : Nil
          if remaining_path == "/" && is_get?
            block_result(yield)
            throw :halt
          end
        end

        def get : Nil
          return unless is_get?

          block_result(yield)
          throw :halt
        end

        def get(arg) : Nil
          return unless is_get?

          path = @remaining_path

          if (result = match(arg)) && empty_path?
            block_result(yield *result)
            throw :halt
          else
            @remaining_path = path
            false
          end
        end

        def post : Nil
          return unless is_post?

          block_result(yield)
          throw :halt
        end

        def post(arg) : Nil
          return unless is_post?

          path = @remaining_path

          if (result = match(arg)) && empty_path?
            block_result(yield *result)
            throw :halt
          else
            @remaining_path = path
            false
          end
        end

        def always : Nil
          block_result(yield)
          throw :halt
        end

        def block_result(result)
          if body = block_result_body(result)
            @response.write(body)
          end
        end

        def block_result_body(result : String)
          result
        end

        def block_result_body(result : Nil)
          # do nothing
        end

        def matched_path : String
          @request.path.rchop(remaining_path)
        end

        private def empty_path? : Bool
          @remaining_path.empty?
        end

        private def match(arg : String)
          rp = @remaining_path
          length = arg.size

          match = case rp.rindex(arg, length)
                  when nil
                    # segment does not match, most common case
                    return
                  when 1
                    # segment matches, check first character is /
                    rp.byte_at?(0) == 47
                  else # must be 0
                    # segment matches at first character, only a match if
                    # empty string given and first character is /
                    length == 0 && rp.byte_at?(0) == 47
                  end

          return unless match

          length += 1
          case rp.byte_at?(length)
          when 47
            # next character is /, update remaining path to rest of string
            @remaining_path = rp[length, 100000000]
            Tuple.new
          when nil
            # end of string, so remaining path is empty
            @remaining_path = ""
            Tuple.new
          else
            # Any other value means this was partial segment match,
            # so we return false in that case without updating the
            # remaining_path.
          end
        end

        private def match(arg : Bool)
          arg ? Tuple.new : nil
        end

        private def match(arg : Regex) : Tuple(Regex::MatchData)?
          matchdata = @remaining_path.match(arg)
          return if matchdata.nil?

          @remaining_path = matchdata.post_match
          {matchdata}
        end

        private def match(arg : Int32.class) : Tuple(Int32)?
          matchdata = @remaining_path.match(/\A\/(\d+)(?=\/|\z)/)
          return if matchdata.nil?

          @remaining_path = matchdata.post_match
          path_var = matchdata.captures.first.not_nil!
          {path_var.to_i}
        end

        private def match(arg : String.class) : Tuple(String)?
          rp = @remaining_path
          return unless rp.byte_at?(0) == 47

          if last = rp.index('/', 1)
            @remaining_path = rp[last, rp.size]
            {rp[1, last - 1]}
          elsif rp.size > 1
            @remaining_path = ""
            {rp[1, rp.size]}
          end
        end

        private def is_get?
          request_method == "GET"
        end

        private def is_post?
          request_method == "POST"
        end

        private def path_matches?(path)
          @request.path == path
        end

        private def request_method
          @request.method.upcase
        end
      end

      module ResponseMethods
        @body : String?
        property status : Int32?

        def initialize(@response : HTTP::Server::Response)
        end

        def write(body)
          @body = body.to_s
        end

        def finish
          set_default_headers
          stat = self.status

          if body = @body
            @response.print(body)
            stat ||= 200
          else
            stat ||= 404
          end
          @response.status = HTTP::Status.new(stat)
        end

        def set_default_headers
          default_headers.each do |k, v|
            @response.headers[k] ||= v
          end
        end

        def default_headers
          {
            "Content-Type" => "text/html",
          }
        end
      end
    end
  end
end
