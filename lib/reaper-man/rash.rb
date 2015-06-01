require 'hashie'
require 'reaper'

module Reaper
  # Helper Hash-style class
  class Rash < Hash
    include Hashie::Extensions::IndifferentAccess
    include Hashie::Extensions::DeepMerge
    include Hashie::Extensions::Coercion

    coerce_value Hash, Rash

    # Fetch value from hash
    #
    # @param args [String, Symbol] argument list
    # @return [Object, NilClass]
    def retrieve(*args)
      args.inject(self) do |memo, key|
        if(memo.is_a?(Hash))
          memo.to_rash[key]
        else
          nil
        end
      end
    end

  end
end

class Hash
  # @return [Reaper::Rash] convert Hash to Rash
  def to_rash
    Reaper::Rash.new.replace(self)
  end
end
