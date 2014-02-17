module Reaper
  class Cli
    class Sign < Cli

      banner 'reaper sign (package|packages) (PACKAGE_FILE|PACKAGES_DIRECTORY)'

      option(:signing_chunk_size,
        :short => '-S SIZE',
        :long => '--signing-chunk-size SIZE',
        :description => 'Number of packages to sign at once',
        :default => 20
      )
      options[:package_system][:required] = true

      def package
        package = parse_options[2]
        signer = Signer.new({:package_system => File.extname(package).tr('.', '')}.merge(config))
        action "Signing package #{package}" do
          signer.package(package)
        end
      end

      def packages
        pkg_dir = parse_options.first
        signer = Signer.new(config)
        action "Signing packages in directory #{pkg_dir}" do
          contents = Dir.glob(File.join(pkg_dir, '**', '*'))
          contents.delete_if{|c| !File.file?(c)}
          signer.package(*contents)
        end
      end

    end
  end
end
