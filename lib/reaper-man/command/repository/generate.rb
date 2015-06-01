require 'reaper-man'

module ReaperMan
  class Command
    class Repository

      class Generate < Repository

        def execute!
          run_action 'Generating repository' do
            ReaperMan::Generator.new(opts).generate!
            nil
          end
        end

      end

    end
  end
end
