module Reaper
  class Signer
    module Deb

      def package(*pkgs)
        pkgs = valid_packages(*pkgs)
        pkgs.each_slice(sign_chunk_size) do |pkgs|
          opts = ["--sign='#{sign_type}'"]
          opts.push("--default-key='#{key_id}'") if key_id
          cmd = (['debsigs'] + opts + pkgs).join(' ')
          shellout!(cmd)
        end
      end

      def valid_packages(*pkgs)
        pkgs.find_all do |pkg|
          File.extname(pkg) == '.deb'
        end
      end

    end
  end
end
