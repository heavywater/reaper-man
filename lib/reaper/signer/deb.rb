module Reaper
  class Signer
    module Deb

      SIGN_COMMAND = File.join(
        File.expand_path(File.join(File.dirname(__FILE__), '..')),
        'util-scripts/auto-debsigs'
      )

      def package(*pkgs)
        pkgs = valid_packages(*pkgs)
        pkgs.each_slice(sign_chunk_size) do |pkgs|
          shellout(
            "#{SIGN_COMMAND} #{sign_type} #{key_id} #{pkgs.join(' ')}",
            :environment => {
              'REAPER_KEY_PASSWORD' => key_password
            }
          )
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
