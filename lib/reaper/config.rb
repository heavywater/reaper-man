require 'delegate'

module Reaper
  class Config < SimpleDelegator

    def initialize(config)
      super config.to_rash
    end

    def format!
    end

    DEFAULT_STRUCTURE = {
      :signing_key => nil,
      :signing_type => nil,
      :package_system => nil,
      :output_directory => nil,
      :packages_file => nil,

    }.to_rash

  end
end
