class Croda
  module CrodaPlugins
    module Base
      module ClassMethods
        macro extended
          @@route_block : (Croda::CrodaRequest ->)?
        end

        def route(&block : Croda::CrodaRequest ->)
          @@route_block = block
        end
      end

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

        def call(context)
          if block = @@route_block
            execute context, &block
            return
          end
          call_next(context)
        end

        def execute(context)
          request = Croda::CrodaRequest.new(context.request, self)
          catch :halt do
            with self yield request
          end
        end
      end

      module RequestMethods
        struct Term
        end

        TERM = Term.new

        def initialize(@request : HTTP::Request, @app : ::Croda)
          @remaining_path = @request.path
        end

        def on(&block)
          always(&block)
        end

        def on(*args, &block)
          if_match(args, &block)
        end

        def is(&block)
          if_match({TERM}, &block)
        end

        def get(&block)
          always(&block) if is_get?
        end

        def get(*args, &block)
          if_match(args, &block) if is_get?
        end

        def post(&block)
          always(&block) if is_post?
        end

        def always
          with @app yield
          throw :halt
        end

        # args is a Tuple
        def if_match(args, &block)
          path = @remaining_path

          if match_all(args)
            always(&block)
          else
            @remaining_path = path
            false
          end
        end

        private def empty_path? : Bool
          @remaining_path.empty?
        end

        private def match_all(args)
          args.all? { |arg| match(arg) }
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

        private def match(arg : Term) : Bool
          empty_path?
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
    end
  end
end
