$LOAD_PATH.unshift File.expand_path(File.dirname(__FILE__)) + '/lib/'
require 'reaper/version'
Gem::Specification.new do |s|
  s.name = 'reaper'
  s.version = Reaper::VERSION.version
  s.summary = 'Reaper repository generator'
  s.author = 'Chris Roberts'
  s.email = 'code@chrisroberts.org'
  s.homepage = 'http://github.com/heavywater/reaper'
  s.description = 'Reaper repository generator'
  s.require_path = 'lib'
  s.add_dependency 'bogo-cli'
  s.add_dependency 'childprocess'
  s.executables << 'reaper'
  s.files = Dir['**/*']
end
