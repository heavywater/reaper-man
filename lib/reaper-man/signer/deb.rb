require 'reaper'

module Reaper
  class Signer
    # Signing methods for deb files
    module Deb

      # command to use for file signing
      SIGN_COMMAND = File.join(
        File.expand_path(File.join(File.dirname(__FILE__), '..')),
        'util-scripts/auto-debsigs'
      )

      # Sign given files
      #
      # @param pkgs [String] list of file paths
      # @return [TrueClass]
      def package(*pkgs)
        pkgs = valid_packages(*pkgs)
        pkgs.each_slice(sign_chunk_size) do |pkgs|
          if(key_password)
            shellout(
              "#{SIGN_COMMAND} #{sign_type} #{key_id} #{pkgs.join(' ')}",
              :environment => {
                'REAPER_KEY_PASSWORD' => key_password
              }
            )
          else
            shellout(%w(debsigs --sign="#{sign_type}" --default-key="#{key_id}" #{pkgs.join(' ')}))
          end
        end
        true
      end

      # Filter only valid paths for signing (.deb extensions)
      #
      # @param pkgs [String] list of file paths
      # @return [Array<String>]
      def valid_packages(*pkgs)
        pkgs.find_all do |pkg|
          File.extname(pkg) == '.deb'
        end
      end

    end
  end
end
