require "reaper-man"

module ReaperMan
  # Standard error for reaper errors
  class Error < StandardError
    # exit code for exception
    CODE = -1

    # @return [Integer]
    def exit_code
      self.class.const_get(:CODE)
    end

    # Define errors here
    ["UnknownCommand", "FileNotFound"].each_with_index do |klass_name, idx|
      self.class_eval("class #{klass_name} < Error; CODE=#{idx + 1}; end;")
    end
  end
end
