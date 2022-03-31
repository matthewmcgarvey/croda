abstract class Croda
  module CrodaPlugins
    module AllVerbs
      module RequestMethods
        macro define_verb(verb)
          def {{ verb.id }} : Nil
            return unless method_matches?({{ verb.upcase }})

            block_result(yield)
            halt
          end

          def {{ verb.id }}(arg) : Nil
            return unless method_matches?({{ verb.upcase }})

            path = @remaining_path

            if (result = match(arg)) && empty_path?
              block_result(yield *result)
              halt
            else
              @remaining_path = path
              false
            end
          end
        end

        define_verb("delete")
        define_verb("head")
        define_verb("options")
        define_verb("link")
        define_verb("patch")
        define_verb("put")
        define_verb("trace")
        define_verb("unlink")
      end
    end

    register_plugin :all_verbs, Croda::CrodaPlugins::AllVerbs
  end
end
