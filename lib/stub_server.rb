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
  end

  def boot
    Thread.new do
      options = {
        Port: @port,
        Logger: WEBrick::Log.new("/dev/null"),
        AccessLog: []
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

      Rack::Handler::WEBrick.run(self, options) { |s| @server = s }
    end
  end

  def wait
    Timeout.timeout(10) do
      loop do
        begin
          socket = TCPSocket.new('localhost', @port)
          socket.close if socket
          sleep 0.1 if ENV['CI']
          return
        rescue Errno::ECONNREFUSED
          nil
        end
      end
    end
  end

  def call(env)
    path = env.fetch("PATH_INFO")
    code, headers, body = @replies[path]
    unless code
      warn "StubServer: Missing reply for path #{path}" # some clients does not show current url when failing
      raise
    end
    body = [body.to_json] if @json
    [code, headers, body]
  end

  def shutdown
    @server.shutdown if @server
  end
end
