require "digest/sha1"
require "digest/sha2"
require "digest/md5"

require "reaper-man"

module ReaperMan
  # Helper utilities
  module Utils
    autoload :Process, "reaper-man/utils/process"

    # Checksum helper
    module Checksum
      def checksum(io, type)
        digest = Digest.const_get(type.to_s.upcase).new
        while data = io.read(2048)
          digest << data
        end
        digest.hexdigest
      end
    end
  end
end
