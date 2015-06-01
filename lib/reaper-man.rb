require 'multi_json'

module ReaperMan
  autoload :Cli, 'reaper-man/cli'
  autoload :Config, 'reaper-man/config'
  autoload :Error, 'reaper-man/error'
  autoload :Generator, 'reaper-man/generator'
  autoload :PackageList, 'reaper-man/package_list'
  autoload :Rash, 'reaper-man/rash'
  autoload :Runner, 'reaper-man/runner'
  autoload :Signer, 'reaper-man/signer'
  autoload :Version, 'reaper-man/version'
  autoload :Utils, 'reaper-man/utils'
end

require 'reaper-man/rash'
