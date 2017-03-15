require 'reaper-man'

module ReaperMan
  class Generator
    # Generator methods for rubygems
    module Rubygems

      # Generate the rubygems repository
      #
      def generate!
        generate_gemstore(package_config[:rubygem])
      end

      def generate_gemstore(gems)
        generate_indexing(gems)
        write_quick_specs(gems.fetch(:release, {}))
        write_quick_specs(gems.fetch(:prerelease, {}))
      end

      def generate_indexing(gems)
        build_spec_file('specs', gems.fetch(:release, {}))
        build_spec_file('latest_specs', gems.fetch(:release, {}))
        build_spec_file('prerelease', gems.fetch(:prerelease, {}))
      end

      def create_index(gems)
        [].tap do |list|
          gems.each do |name, all|
            all.each do |version, info|
              list << [name, Gem::Version.new(version.dup), info[:platform]]
            end
          end
        end
      end

      def marshal_path
        ['Marshal', marshal_version].join('.')
      end

      def marshal_version
        [Marshal::MAJOR_VERSION, Marshal::MINOR_VERSION].join('.')
      end

      def build_spec_file(name, gems)
        index = create_index(gems)
        create_file("#{name}.#{marshal_version}") do |file|
          file.write(Marshal.dump(index))
        end
        compress_file("#{name}.#{marshal_version}")
      end

      def write_quick_specs(gems)
        gems.each do |name, list|
          list.each do |version, info|
            spec = Gem::Specification.new(name)
            info.each do |var, value|
              if(spec.respond_to?("#{var}="))
                begin
                  # Ensure we convert Smash instances
                  value = value.to_hash if value.is_a?(Hash)
                  spec.send("#{var}=", value)
                rescue Gem::InvalidSpecificationException => e
                  # TODO: Do we have a logger in this project?
                end
              end
            end
            spec.version = Gem::Version.new(info[:version])
            spec.date = Time.parse(info[:date])
            info[:dependencies].each do |dep|
              spec.add_dependency(*dep)
            end
            deflator = Zlib::Deflate.new
            create_file('quick', marshal_path, "#{name}-#{version}.gemspec.rz") do |file|
              file.write(deflator.deflate(Marshal.dump(spec), Zlib::SYNC_FLUSH))
              file.write(deflator.finish)
            end
          end
        end
      end

      # Sign file if configured for signing
      #
      # @yield block returning file path
      # @return [String] file path
      def sign_file_if_setup
        path = yield
        if(signer && options[:sign])
          signer.file(path)
        end
        path
      end

    end
  end
end
