require 'hashie'

module Reaper
  class Rash < Hash
    include Hashie::Extensions::IndifferentAccess
    include Hashie::Extensions::DeepMerge
    include Hashie::Extensions::Coercion

    coerce_value Hash, Rash

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
  def to_rash
    Reaper::Rash.new.replace(self)
  end
end
