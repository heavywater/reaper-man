module Reaper
  class Cli
    class Package < Cli

      banner 'reaper package (add|remove|description|version) [PACKAGE_FILE]'

      option(:origin,
        :short => '-o NAME',
        :long => '--origin NAME',
        :description => 'Name of origin',
        :default => 'Default'
      )
      option(:codename,
        :short => '-c CODENAME',
        :long => '--codename CODENAME',
        :description => 'Code name to add package',
        :default => 'all'
      )
      option(:component,
        :short => '-C COMPONENT',
        :long => '--component COMPONENT',
        :description => 'Component name to add package',
        :default => 'main'
      )
      options[:packages_file][:required] = true

      def add
        file_path = parse_options[2]
        action "Adding package #{file_path}" do
          list = PackageList.new(config[:packages_file], config)
          list.add_package(file_path)
          list.write!
        end
      end

      def version
      end

      def description
      end

      def remove
        action "Removing package #{parse_options[2]}" do
          list = PackageList.new(config[:packages_file], config)
          list.remove_package(*parse_options[2,2])
          list.write!
        end
      end

    end
  end
end
