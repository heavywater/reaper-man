require 'reaper-man'

module ReaperMan
  class Command
    class Package

      class Remove < Package

        def execute!
          arguments.each do |pkg|
            run_action "Remove package from repository manifest: #{pkg}" do
              list = ReaperMan::PackageList.new(options[:packages_file], options)
              list.remove_package(pkg)
              list.write!
              nil
            end
          end
        end

      end

    end
  end
end
