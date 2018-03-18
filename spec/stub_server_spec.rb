# frozen_string_literal: true
require "spec_helper"
require "open-uri"
require "json"
require "logger"

Thread.abort_on_exception = true

SingleCov.covered!

describe StubServer do
  it "has a VERSION" do
    expect(StubServer::VERSION).to match(/^[\.\da-z]+$/)
  end

  describe "Readme" do
    before { allow_any_instance_of(StubServer).to receive(:warn) }
    code = File.read('Readme.md')[/```Ruby\n(.*?)```/m, 1]
    eval(code) # rubocop:disable Security/Eval
  end

  it "can connect via ssl" do
    ssl = {cert: File.read('spec/test.cert'), key: File.read('spec/test.key')}
    StubServer.open(3000, {"/hello" => [200, {}, ["World"]]}, ssl: ssl) do |server|
      server.wait
      expect(open("https://localhost:3000/hello", ssl_verify_mode: OpenSSL::SSL::VERIFY_NONE).read).to eq "World"
    end
  end

  it "can return json" do
    replies = {"/hello" => [200, {}, {foo: :bar}]}
    StubServer.open(3000, replies, json: true) do |server|
      server.wait
      replies["/hello"][2][:foo] = "changed"
      expect(open("http://localhost:3000/hello").read).to eq '{"foo":"changed"}'
    end
  end

  it "can override webrick options json" do
    replies = {"/hello" => [200, {}, ["World"]]}
    devise = StringIO.new
    logger = Logger.new(devise)
    StubServer.open(3000, replies, webrick: {Logger: logger}) do |server|
      server.wait
      expect(open("http://localhost:3000/hello").read).to eq "World"
      expect(devise.string).to include "Rack::Handler::WEBrick is invoked"
    end
  end

  it "does not crash when shutdown without server" do
    expect(Rack::Handler::WEBrick).to receive(:run)
    StubServer.open(3000, {"/hello" => [200, {}, ["World"]]}, &:shutdown)
    sleep 0.1
  end
end
