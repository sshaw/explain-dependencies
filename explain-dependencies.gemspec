require File.expand_path("../lib/xdep/version", __FILE__)
require "date"

Gem::Specification.new do |s|
  s.name        = "explain-dependencies"
  s.version     = XDep::VERSION
  s.date        = Date.today
  s.summary     = "Explains what your project's dependencies are."
  s.authors     = ["Skye Shaw"]
  s.email       = "skye.shaw@gmail.com"
  s.executables  << "xdep"
  s.test_files  = Dir["spec/**/*.*"]
  s.extra_rdoc_files = %w[README.md]
  s.files       = Dir["lib/**/*.rb"] + s.test_files + s.extra_rdoc_files
  s.homepage    = "http://github.com/sshaw/explain-dependencies"
  s.license     = "MIT"
  s.add_development_dependency "rake", "~> 0.9"
end
