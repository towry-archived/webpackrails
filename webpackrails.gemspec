# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'webpackrails/version'

Gem::Specification.new do |spec|
  spec.name          = "webpackrails"
  spec.version       = WebpackRails::VERSION
  spec.authors       = ["towry"]
  spec.email         = ["tovvry@gmail.com"]

  spec.summary       = %q{Make Webpack work with Rails for you}
  spec.description   = %q{Webpack + Rails ≠ CommonJS Heaven}
  spec.homepage      = "https://github.com/towry/webpackrails"
  spec.license       = "MIT"

  # Prevent pushing this gem to RubyGems.org by setting 'allowed_push_host', or
  # delete this section to allow pushing this gem to any host.
  if spec.respond_to?(:metadata)
    spec.metadata['allowed_push_host'] = "https://rubygems.org"
  else
    raise "RubyGems 2.0 or newer is required to protect against public gem pushes."
  end

  spec.files         = `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_runtime_dependency "railties", "~> 4.2", "<= 5.0.0"
  spec.add_runtime_dependency "sprockets", "~> 2.0"

  spec.add_development_dependency "rake", "~> 10.0"
  spec.add_development_dependency "bundler", ">= 1.3"
  spec.add_development_dependency "rails"
  spec.add_development_dependency "pry"
  spec.add_development_dependency "tilt"
end
