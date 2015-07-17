require 'reaper-man'

module ReaperMan
  class Command
    class Repository

      class Generate < Repository

        def execute!
          run_action 'Generating repository' do
            ReaperMan::Generator.new(
              config.merge(
                Smash.new(
                  :package_config => MultiJson.load(
                    File.read(config[:packages_file])
                  ).to_smash,
                  :signer => config[:sign] ? Signer.new(config) : nil
                )
              )
            ).generate!
            nil
          end
        end

      end

    end
  end
end
