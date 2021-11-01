# coding: utf-8

lib = File.expand_path("../lib", __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require "csa/version"

Gem::Specification.new do |spec|
  spec.name = "csa"
  spec.version = Csa::VERSION
  spec.authors = ["dianyi j"]
  spec.email = ["lastobject@gmail.com"]

  spec.summary = %q{create swift app}
  spec.description = %q{a command line tool helps you create a swift app from a template}
  spec.homepage = "https://rubygems.org/gems/csa"
  spec.required_ruby_version = Gem::Requirement.new(">= 2.3.0")

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = "https://github.com/djiangnz/csa"
  spec.metadata["changelog_uri"] = "https://github.com/djiangnz/csa/CHANGELOG.md"

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  spec.files = Dir.chdir(File.expand_path("..", __FILE__)) do
    `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  end

  spec.bindir = "exe"
  spec.executables = spec.files.grep(%r{^#{spec.bindir}/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_dependency "gli", "~> 2.19"
  spec.add_dependency "xcodeproj", "~> 1.18"
  spec.add_dependency "cli-ui", "~> 1.3"
  spec.add_development_dependency "rspec", "~> 3.2"
end
