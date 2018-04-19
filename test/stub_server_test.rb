# frozen_string_literal: true
require_relative "test_helper"
require "open-uri"
require "json"
require "logger"

Thread.abort_on_exception = true

SKIP_TIMEOUT_HANDLERS = (RUBY_VERSION < "2.4.0" || ENV["TRAVIS"])

SingleCov.covered! uncovered: (SKIP_TIMEOUT_HANDLERS ? 2 : 1)

describe StubServer do
  def port_free?
    !system("lsof -i:#{port}", out: '/dev/null')
  end

  let(:port) { 3214 }

  after do
    # we need to cleanup since ruby 2.3 cannot do it
    WEBrick::Utils::TimeoutHandler.instance.instance_variable_get(:@watcher).kill.join if RUBY_VERSION < "2.4.0"
    if maxitest_extra_threads.any? # give stragglers a chance, ideally should not be necessary
      puts "Extra thread found, waiting 1s"
      sleep 1
    end
    assert port_free?, "port is still in use"
  end

  it "has a VERSION" do
    StubServer::VERSION.must_match(/^[\.\da-z]+$/)
  end

  describe "Readme" do
    before { StubServer.any_instance.stubs(:warn) }
    code = File.read('Readme.md')[/```Ruby\n(.*?)```/m, 1]
    eval(code, binding, 'Readme.md', 14) # rubocop:disable Security/Eval
  end

  it "can connect via ssl" do
    ssl = {cert: File.read('test/test.cert'), key: File.read('test/test.key')}
    StubServer.open(port, {"/hello" => [200, {}, ["World"]]}, ssl: ssl) do |server|
      server.wait
      open("https://localhost:#{port}/hello", ssl_verify_mode: OpenSSL::SSL::VERIFY_NONE).read.must_equal "World"
    end
  end

  it "can return json" do
    replies = {"/hello" => [200, {}, {foo: :bar}]}
    StubServer.open(port, replies, json: true) do |server|
      server.wait
      replies["/hello"][2][:foo] = "changed"
      open("http://localhost:#{port}/hello").read.must_equal '{"foo":"changed"}'
    end
  end

  it "can override webrick options json" do
    replies = {"/hello" => [200, {}, ["World"]]}
    devise = StringIO.new
    logger = Logger.new(devise)
    StubServer.open(port, replies, webrick: {Logger: logger}) do |server|
      server.wait
      open("http://localhost:#{port}/hello").read.must_equal "World"
      devise.string.must_include "Rack::Handler::WEBrick is invoked"
    end
  end

  it "does not crash when shutdown without server" do
    Rack::Handler::WEBrick.expects(:run)
    StubServer.open(port, "/hello" => [200, {}, ["World"]]) do |server|
      Thread.pass
      sleep 1
      server.shutdown
    end
    sleep 0.1
  end

  it "can nest servers" do
    called = nil
    StubServer.open(port, "/hello" => [200, {}, ["World"]]) do |a|
      StubServer.open(port + 1, "/hello" => [200, {}, ["World"]]) do |b|
        a.wait
        b.wait
        open("http://localhost:#{port}/hello").read.must_equal "World"
        open("http://localhost:#{port + 1}/hello").read.must_equal "World"
        called = 1
      end
    end
    assert called
  end

  describe "timout handler" do
    before { skip "does not work on travis + old rubies" } if SKIP_TIMEOUT_HANDLERS

    it "does not shutdown timeout when it is still being used" do
      WEBrick::Utils::TimeoutHandler.register(5, RuntimeError)

      StubServer.open(port, "/hello" => [200, {}, ["World"]]) do |_a|
        open("http://localhost:#{port}/hello").read.must_equal "World"
      end

      # should not be terminated since we might still need it
      refute WEBrick::Utils::TimeoutHandler.instance.instance_variable_get(:@timeout_info).empty?
      WEBrick::Utils::TimeoutHandler.terminate
    end

    it "can use timeout after shutdown" do
      # create a terminated timeout handler
      StubServer.open(port, "/hello" => [200, {}, ["World"]]) do |_a|
        open("http://localhost:#{port}/hello").read.must_equal "World"
      end

      # check if it still works
      WEBrick::Utils::TimeoutHandler.register(0, RuntimeError)
      assert_raises { sleep 2 }
      WEBrick::Utils::TimeoutHandler.terminate
    end
  end
end
