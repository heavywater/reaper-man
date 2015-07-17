require 'reaper-man'

module ReaperMan
  class Generator
    # Generator methods for apt
    module Apt

      # Generate the repository
      def generate!
        generate_dists(package_config[:apt])
      end

      # Generate the repository dists
      #
      # @param pkg_hash [Hash] repository description
      # @return [TrueClass]
      def generate_dists(pkg_hash)
        pkg_hash.each do |origin_name, dists|
          dists.each do |dist_name, dist_args|
            dist_args[:components].each do |component_name, arches|
              arches.each do |arch_name, packages|
                package_file(origin_name, dist_name, component_name, arch_name, packages)
                release_headers = Smash.new
                release_headers['Label'] = dist_args['label']
                release_headers['Archive'] = dist_name
                sign_file_if_setup do
                  release_file(origin_name, dist_name, component_name, arch_name, release_headers)
                end
              end
            end
            release_headers = Smash[
              %w(Codename Suite Label Description Version).map do |field_name|
                if(val = dist_args[field_name.downcase])
                  [field_name, val]
                end
              end.compact
            ]
            release_headers['Components'] = dist_args[:components].keys.join(' ')
            signed = sign_file_if_setup('--clearsign') do
              release_file(origin_name, dist_name, release_headers)
            end
            if(File.exists?("#{signed}.gpg"))
              FileUtils.mv(
                "#{signed}.gpg",
                File.join(File.dirname(signed), 'InRelease')
              )
            end
            sign_file_if_setup do
              release_file(origin_name, dist_name, release_headers)
            end
          end
        end
        true
      end

      # Sign file if configured for signing
      #
      # @yield block returning file path
      # @return [String] file path
      def sign_file_if_setup(opts=nil)
        path = yield
        if(signer && options[:sign])
          signer.file(path, nil, opts)
        end
        path
      end

      # Create Packages file
      #
      # @param args [String] argument list for file path
      # @return [String] path to compressed Packages file
      def package_file(*args)
        pkgs = args.pop
        args.insert(1, 'dists')
        create_file(*args.push('Packages')) do |file|
          pkgs.each do |pkg_name, pkgs|
            pkgs.each do |pkg_version, pkg_meta|
              pkg_meta.each do |field_name, field_value|
                if(field_value)
                  file.puts "#{field_name}: #{field_value}"
                end
              end
              file.puts
            end
          end
        end
        compress_file(*args)
      end

      # Create Release file
      #
      # @param args [String] argument list for file path
      # @return [TrueClass]
      def release_file(*args)
        header = args.detect{|a| a.is_a?(Hash)}
        header ? args.delete(header) : header = Smash.new
        header.merge(Smash[%w(Origin Codename Component Architecture).zip(args)])
        header['Date'] = Time.now.utc.strftime('%a, %d %b %Y %H:%M:%S %Z')
        args.insert(1, 'dists')
        create_file(*args.dup.push('Release')) do |file|
          contents = Dir.glob(File.join(File.dirname(file.path), '**', '*'))
          header_content = header.map do |key, value|
            next unless value
            "#{key.to_s.capitalize}: #{value}"
          end.compact.join("\n")
          file.puts header_content
          [['MD5Sum', :md5], ['SHA1', :sha1], ['SHA256', :sha256]].each do |field, digest|
            file.puts "#{field}:"
            contents.each do |content|
              next if File.expand_path(content) == File.expand_path(file.path) || File.directory?(content)
              File.open(content, 'r') do |content_file|
                line = [' ']
                line << checksum(content_file, digest)
                line << content_file.size
                line << content_file.path.sub(File.dirname(file.path), '').sub(/^\//, '')
                file.puts line.join(' ')
              end
            end
          end
          true
        end
      end

    end
  end
end
