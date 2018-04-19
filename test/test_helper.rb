# frozen_string_literal: true
require "bundler/setup"

require "single_cov"
SingleCov.setup :minitest

require "stub_server/version"
require "stub_server"

require "maxitest/autorun"
require "maxitest/timeout"
require "maxitest/threads"
require "mocha/setup"
