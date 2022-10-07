# frozen_string_literal: true
name = "stub_server"
require "./lib/#{name.tr("-", "/")}/version"

Gem::Specification.new name, StubServer::VERSION do |s|
  s.summary = "Boot up a real server to serve testing replies"
  s.authors = ["Michael Grosser"]
  s.email = "michael@grosser.it"
  s.homepage = "https://github.com/grosser/#{name}"
  s.files = `git ls-files lib/ bin/ MIT-LICENSE`.split("\n")
  s.license = "MIT"
  s.required_ruby_version = '>= 2.7.0'
  s.add_runtime_dependency "rackup", "~> 0.2.2"
  s.add_runtime_dependency "webrick"
end
