Boot up a real server to serve testing replies

Install
=======

```Bash
gem install stub_server
```

Usage
=====

```Ruby
require 'stub_server'
require 'open-uri'

describe "Stub Server" do
  let(:port) { 9123 }
  let(:replies) { { "/hello" => [200, {}, ["World"]] } }
  
  it "can connect" do
    StubServer.open(port, replies) do |server|
      server.wait # ~ 0.1s
      open("http://localhost:#{port}/hello").read.must_equal "World"
    end
  end
  
  it "fails on unknown paths" do
    StubServer.open(port, replies) do |server|
      server.wait
      assert_raises(OpenURI::HTTPError) { open("http://localhost:#{port}/no").read }
    end
  end
end
```

 - Enable ssl `ssl: {cert: File.read(cert), key: File.read(key)}`
 - override other options by passing in `WebBrick` options, see `lib/stub_server.rb`
 - Use `json: true` to make all replies `.to_json` before sending, this is useful when modifying replies inside of tests 

Author
======
[Michael Grosser](http://grosser.it)<br/>
michael@grosser.it<br/>
License: MIT<br/>
[![Build Status](https://travis-ci.org/grosser/stub_server.png)](https://travis-ci.org/grosser/stub_server)
