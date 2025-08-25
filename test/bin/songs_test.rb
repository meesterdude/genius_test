require "test_helper"
require "stringio"

load File.expand_path("../../bin/songs", __dir__)

class ArtistSongsCLITest < Minitest::Test
  class MockProvider
    def initialize(mock)
      @mock = mock
    end

    def artist_songs(*args)
      @mock.artist_songs(*args)
    end
  end

  def setup
    @mock_provider = Minitest::Mock.new
    @mock_provider.expect :artist_songs,
                          { songs: ["Song 1", "Song 2"], current_page: 1, next_page: nil },
                          ["Queen", { start_page: 1, max_pages: nil }]

    @provider_factory = ->(**_) { MockProvider.new(@mock_provider) }
  end

  def test_run_outputs_songs
    out = StringIO.new
    env = { "GENIUS_ACCESS_TOKEN" => "FAKE_TOKEN" }

    ArtistSongsCLI.run(["Queen"], out: out, env: env, provider_class: @provider_factory)
    output = out.string

    assert_match(/Songs for Queen/, output)
    assert_match(/Song 1/, output)
    assert_match(/Song 2/, output)
    @mock_provider.verify
  end

  def test_missing_arguments_exits
    out = StringIO.new
    env = { "GENIUS_ACCESS_TOKEN" => "FAKE_TOKEN" }

    assert_raises(SystemExit) do
      ArtistSongsCLI.run([], out: out, env: env, provider_class: @provider_factory)
    end
    assert_match(/Usage/, out.string)
  end

  def test_missing_token_exits
    out = StringIO.new
    env = {}

    assert_raises(SystemExit) do
      ArtistSongsCLI.run(["Queen"], out: out, env: env, provider_class: @provider_factory)
    end
    assert_match(/Set GENIUS_ACCESS_TOKEN/, out.string)
  end
end
