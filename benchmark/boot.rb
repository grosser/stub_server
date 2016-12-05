# frozen_string_literal: true
require 'bundler/setup'
require 'stub_server'
require 'open-uri'

StubServer.open(3000, "/foo" => [200, {}, ["OK"]]) do |server|
  server.wait
  raise "WRONG" unless open('http://localhost:3000/foo').read == "OK"
end
