require 'reaper-man'

module ReaperMan
  class Signer
    # Signing methods for deb files
    module Deb

      # Sign given files
      #
      # @param pkgs [String] list of file paths
      # @return [TrueClass]
      def package(*pkgs)
        pkgs = valid_packages(*pkgs)
        pkgs.each_slice(sign_chunk_size) do |pkgs|
          cmd = %(debsigs --sign="#{sign_type}" --default-key="#{key_id}" #{pkgs.join(' ')})
          if(key_password)
            shellout(
              "#{Signer::HELPER_COMMAND} #{cmd}",
              :environment => {
                'REAPER_KEY_PASSWORD' => key_password
              }
            )
          else
            shellout(cmd)
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
