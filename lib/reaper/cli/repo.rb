module Reaper
  class Cli
    class Repo < Cli

      option(:package_system,
        :short => '-s PACKAGE_SYSTEM',
        :long => '--package-system PACKAGE_SYSTEM',
        :description => 'Packaging system to generate repository (apt/yum)',
        :required => true
      )

      option(:output_directory,
        :short => '-o DIRECTORY',
        :long => '--output-directory DIRECTORY',
        :default => Dir.pwd,
        :description => 'Directory to output file structure',
        :required => true
      )

      option(:packages_file,
        :short => '-p FILE',
        :long => '--packages-file FILE',
        :description => 'Path to JSON packages file',
        :required => true
      )

      def create
        parse_options
        action "Generating repository" do
          Generator.new(
            config.merge(
              :package_system => config[:package_system],
              :package_config => load_json(config[:packages_file]),
              :signer => signer
            ).to_rash
          ).generate!
        end
      end
      alias_method :update, :create

    end

  end
end
