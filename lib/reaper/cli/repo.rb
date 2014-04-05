module Reaper
  class Cli
    class Repo < Cli

      banner 'reaper package (create|update)'

      option(:output_directory,
        :short => '-o DIRECTORY',
        :long => '--output-directory DIRECTORY',
        :default => Dir.pwd,
        :description => 'Directory to output file structure',
        :required => true
      )
      options[:package_system][:required] = true
      options[:packages_file][:required] = true

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
