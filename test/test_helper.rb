# frozen_string_literal: true

require "minitest/autorun"
require "minitest/reporters"
require "webmock/minitest"
require "dotenv"
require_relative "../lib/providers/providers"

Minitest::Reporters.use! Minitest::Reporters::SpecReporter.new
WebMock.disable_net_connect!(allow_localhost: true)
