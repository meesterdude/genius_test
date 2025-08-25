# test/base_provider_test.rb
require "test_helper"

class BaseProviderTest < Minitest::Test
  def setup
    @provider = Providers::BaseProvider.new
  end

  def test_artist_songs_raises_not_implemented
    error = assert_raises(NotImplementedError) do
      @provider.artist_songs("Any Artist")
    end
    assert_match (/BaseProvider must implement #artist_songs/), error.message
  end
end
