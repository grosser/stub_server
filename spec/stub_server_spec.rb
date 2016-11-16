require "spec_helper"

SingleCov.covered!

describe StubServer do
  it "has a VERSION" do
    expect(StubServer::VERSION).to match /^[\.\da-z]+$/
  end
end
