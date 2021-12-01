# frozen_string_literal: true
require 'rack'
require 'webrick'

class StubServer
  def self.open(port, replies, **options)
    server = new(port, replies, **options)
    server.boot
    yield server
  ensure
    server.shutdown
  end

  def initialize(port, replies, ssl: false, json: false, webrick: {})
    @port = port
    @replies = replies
    @ssl = ssl
    @json = json
    @webrick = webrick
    @started = false
    @server = nil
    @thread = nil
  end

  def boot
    @thread = Thread.new do
      options = {
        Port: @port,
        Logger: WEBrick::Log.new("/dev/null"),
        AccessLog: [],
        DoNotReverseLookup: true, # http://stackoverflow.com/questions/1156759/webrick-is-very-slow-to-respond-how-to-speed-it-up
        StartCallback: -> { @started = true }
      }

      if @ssl
        require 'webrick/https'
        require 'openssl' # can be slow / break ... so keeping it nested

        options.merge!(
          SSLEnable: true,
          SSLVerifyClient: OpenSSL::SSL::VERIFY_NONE,
          SSLCertificate: OpenSSL::X509::Certificate.new(@ssl.fetch(:cert)),
          SSLPrivateKey: OpenSSL::PKey::RSA.new(@ssl.fetch(:key)),
          SSLCertName: [["CN", 'not-a-valid-cert']]
        )
      end

      options.merge!(@webrick)

      Rack::Handler::WEBrick.run(self, **options) { |s| @server = s }
    end
  end

  def wait
    Timeout.timeout(10) { sleep 0.1 until @started }
  end

  def call(env)
    path = env.fetch("PATH_INFO")
    code, headers, body = @replies[path]
    unless code
      warn "StubServer #{@port}: Missing reply for path #{path}" # some clients does not show current url when failing
      raise
    end
    body = [body.to_json] if @json
    [code, headers, body]
  end

  def shutdown
    @server&.shutdown
    @thread.join # need to wait here and cannot simpliy kill or webbrick keeps running

    # TimeoutHandler keeps running forever which breaks tests that assert no extra threads
    # we should only stop it if it is empty, otherwise we are still waiting for other servers
    # ideally we'd use WEBrick::Utils::TimeoutHandler::TimeoutMutex.synchronize to avoid race conditions,
    # but that is also used in .terminate and would lead to deadlocks ...
    # TODO: open ruby issue for race-condition free terminate_if_empty
    if WEBrick::Utils::TimeoutHandler.instance.instance_variable_get(:@timeout_info).empty?
      WEBrick::Utils::TimeoutHandler.terminate
    end
  end
end
