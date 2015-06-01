require 'reaper'

module Reaper
  class Cli
    # CLI helpers for repo interactions
    class Repo < Cli

      banner 'reaper repo (create|update)'

      option(:output_directory,
        :short => '-o DIRECTORY',
        :long => '--output-directory DIRECTORY',
        :default => Dir.pwd,
        :description => 'Directory to output file structure',
        :required => true
      )
      options[:package_system][:required] = true
      options[:packages_file][:required] = true

      # Generate the repository
      #
      # @return [TrueClass]
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
        true
      end
      alias_method :update, :create

    end

  end
end
