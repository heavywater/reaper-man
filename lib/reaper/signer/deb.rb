module Reaper
  class Signer
    module Deb

      def package(*packages)
        verify_type!(packages)
        packages.each_slice(sign_chunk_size) do |pkgs|
          opts = ["--sign='#{sign_type}'"]
          opts.push("--default-key='#{key_id}'")
          cmd = (['debsigs'] + opts + pkgs).join(' ')
          shellout!(cmd)
        end
      end

    end
  end
end
