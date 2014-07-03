require 'delegate'
require 'reaper'

module Reaper
  # Configuration helper
  class Config < SimpleDelegator

    # Create new instance
    #
    # @param config [Hash]
    def initialize(config)
      super config.to_rash
    end

    # @todo implement
    def format!
    end

    # Default configuration structure
    DEFAULT_STRUCTURE = {
      :signing_key => nil,
      :signing_type => nil,
      :package_system => nil,
      :output_directory => nil,
      :packages_file => nil
    }.to_rash

  end
end
