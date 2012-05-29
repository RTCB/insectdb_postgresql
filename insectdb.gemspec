# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)
require "insectdb/version"

Gem::Specification.new do |s|
  s.name        = "insectdb"
  s.version     = Insectdb::VERSION
  s.authors     = ["Andrey Zaika"]
  s.email       = ["anzaika@gmail.com"]
  s.homepage    = ""
  s.summary     = %q{An interface to insectdb database}
  s.description = %q{}

  s.rubyforge_project = "insectdb"

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ["lib"]

  # Development dependencies
  s.add_development_dependency "rspec"
  s.add_development_dependency "mocha"
  s.add_development_dependency "fakefs"

  # Runtime dependencies
  s.add_runtime_dependency "pg"
  s.add_runtime_dependency "activerecord"
  s.add_runtime_dependency "bio"
  s.add_runtime_dependency "parallel"
end
