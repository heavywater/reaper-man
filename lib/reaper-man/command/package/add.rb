require 'reaper-man'

module ReaperMan
  class Command
    class Package

      class Add < Package

        def execute!
          arguments.each do |path|
            run_action "Adding package to repository manifest: #{path}" do
              list = ReaperMan::PackageList.new(options[:packages_file], options)
              list.add_package(path)
              list.write!
              nil
            end
          end
        end

      end

    end
  end
end
