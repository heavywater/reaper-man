require 'digest/sha1'
require 'digest/sha2'
require 'digest/md5'

module Reaper
  module Utils

    module Process

      # NOTE: These are stubs for now. Will replace with
      # mixlib-shellout and childprocess compat bits with auto
      # detection later

      def shellout!(cmd)
        unless(system(cmd))
          raise "COMMAND FAILED! (#{cmd})"
        end
      end

      def shellout(cmd)
        %x{#{cmd}}
      end

    end

    module Checksum

      def checksum(io, type)
        digest = Digest.const_get(type.to_s.upcase).new
        while(data = io.read(2048))
          digest << data
        end
        digest.hexdigest
      end

    end

  end
end
