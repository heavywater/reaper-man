require 'reaper-man'

module ReaperMan
  class Command
    class Package

      class Remove < Package

        def execute!
          args.each do |pkg|
            run_action "Remove package from repository manifest: #{pkg}" do
              list = ReaperMan::PackageList.new(opts[:packages_file], opts)
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
