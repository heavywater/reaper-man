require 'reaper-man'

module ReaperMan
  class Command
    class Package

      class Add < Package

        def execute!
          args.each do |path|
            run_action "Adding package to repository manifest: #{path}" do
              list = ReaperMan::PackageList.new(opts[:packages_file], opts)
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
