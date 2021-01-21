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

        def execute(context)
          response = Croda::CrodaResponse.new(context.response)
          request = Croda::CrodaRequest.new(context.request, response, self)
          catch :halt do
            yield request
          end
        end
      end

      module RequestMethods
        @request : HTTP::Request
        @response : Croda::CrodaResponse
        @remaining_path : String

        def initialize(@request : HTTP::Request, @response : Croda::CrodaResponse, @app : ::Croda)
          @remaining_path = @request.path
        end

        def on(&block)
          always(&block)
        end

        def on(arg : String, &block)
          if_match(arg, &block)
        end

        def on(arg : T.class, &block : T -> _) forall T
          if_match(arg, &block)
        end

        def is(&block)
          always(&block) if empty_path?
        end

        def is(arg : String, &block)
          if_match(arg, terminal: true, &block)
        end

        def is(arg : T.class, &block : T -> _) forall T
          if_match(arg, terminal: true, &block)
        end

        def get(&block)
          always(&block) if is_get?
        end

        def get(arg : String, &block)
          if_match(arg, terminal: true, &block) if is_get?
        end

        def get(arg : T.class, &block : T -> _) forall T
          if_match(arg, terminal: true, &block) if is_get?
        end

        def post(&block)
          always(&block) if is_post?
        end

        def post(arg : String, &block)
          if_match(arg, terminal: true, &block) if is_post?
        end

        def post(arg : T.class, &block : T -> _) forall T
          if_match(arg, terminal: true, &block) if is_post?
        end

        def always
          block_result(with @app yield)
          throw :halt
        end

        def if_match(arg : String, terminal = false)
          path = @remaining_path

          if match(arg) && (!terminal || empty_path?)
            block_result(with @app yield)
            throw :halt
          else
            @remaining_path = path
            false
          end
        end

        def if_match(arg : T.class, terminal = false) forall T
          path = @remaining_path

          if (result = match(arg)) && (!terminal || empty_path?)
            block_result(with @app yield result)
            throw :halt
          else
            @remaining_path = path
            false
          end
        end

        def block_result(result)
          if body = block_result_body(result)
            @response.headers.add("Content-Type", "text/html")
            @response.print(body)
          end
        end

        def block_result_body(result : String)
          result
        end

        def block_result_body(result : Nil)
          # do nothing
        end

        private def empty_path? : Bool
          @remaining_path.empty?
        end

        private def match(arg : String) : Bool
          rp = @remaining_path
          length = arg.size

          match = case rp.rindex(arg, length)
                  when nil
                    # segment does not match, most common case
                    return false
                  when 1
                    # segment matches, check first character is /
                    rp.byte_at?(0) == 47
                  else # must be 0
                    # segment matches at first character, only a match if
                    # empty string given and first character is /
                    length == 0 && rp.byte_at?(0) == 47
                  end

          return false unless match

          length += 1
          case rp.byte_at?(length)
          when 47
            # next character is /, update remaining path to rest of string
            @remaining_path = rp[length, 100000000]
            true
          when nil
            # end of string, so remaining path is empty
            @remaining_path = ""
            true
          else
            # Any other value means this was partial segment match,
            # so we return false in that case without updating the
            # remaining_path.
            false
          end
        end

        private def match(arg : Int32.class) : Int32?
          matchdata = @remaining_path.match(/\A\/(\d+)(?=\/|\z)/)
          return if matchdata.nil?

          @remaining_path = matchdata.post_match
          path_var = matchdata.captures.first.not_nil!
          path_var.to_i
        end

        private def match(arg : String.class) : String?
          rp = @remaining_path
          return unless rp.byte_at?(0) == 47

          if last = rp.index('/', 1)
            @remaining_path = rp[last, rp.size]
            rp[1, last - 1]
          elsif rp.size > 1
            @remaining_path = ""
            rp[1, rp.size]
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
        def initialize(@response : HTTP::Server::Response)
        end

        forward_missing_to @response
      end
    end
  end
end
