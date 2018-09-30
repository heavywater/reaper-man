require "reaper-man"

module ReaperMan
  class Signer
    module Rubygems
      def package(*pkgs)
        nil
      end

      def valid_packages(*pkgs)
        nil
      end
    end
  end
end
