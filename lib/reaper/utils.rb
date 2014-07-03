require 'digest/sha1'
require 'digest/sha2'
require 'digest/md5'

require 'reaper'

module Reaper
  # Helper utilities
  module Utils

    autoload :Process, 'reaper/utils/process'

    # Checksum helper
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
