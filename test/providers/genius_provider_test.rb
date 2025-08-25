# test/genius_provider_test.rb
require "test_helper"
require "webmock/minitest"

class GeniusProviderTest < Minitest::Test
  def setup
    @access_token = "FAKE_TOKEN"
    @provider = Providers.get(:genius, access_token: @access_token)
  end

  # --- Helpers ---
  def stub_search_artist(artist_name, artist_id)
    stub_request(:get, /search/)
      .with(query: { q: artist_name },
            headers: { "Authorization" => "Bearer #{@access_token}" })
      .to_return(
        status: 200,
        body: {
          response: {
            hits: [
              { result: { primary_artist: { id: artist_id, name: artist_name } } }
            ]
          }
        }.to_json,
        headers: { "Content-Type" => "application/json" }
      )
  end

  def stub_artist_songs_page(artist_id, page, songs, next_page)
    stub_request(:get, /artists\/#{artist_id}\/songs/)
      .with(query: hash_including({ "page" => page.to_s }),
            headers: { "Authorization" => "Bearer #{@access_token}" })
      .to_return(
        status: 200,
        body: {
          response: {
            songs: songs.map { |t| { "title" => t } },
            next_page: next_page
          }
        }.to_json,
        headers: { "Content-Type" => "application/json" }
      )
  end

  # --- Tests ---
  def test_artist_songs_single_page
    stub_search_artist("Queen", 123)
    stub_artist_songs_page(123, 1, ["Bohemian Rhapsody"], nil)

    result = @provider.artist_songs("Queen")
    assert_equal ["Bohemian Rhapsody"], result[:songs]
    assert_equal 1, result[:current_page]
    assert_nil result[:next_page]
  end

  def test_artist_songs_multiple_pages
    stub_search_artist("Queen", 123)
    stub_artist_songs_page(123, 1, ["Song 1"], 2)
    stub_artist_songs_page(123, 2, ["Song 2"], nil)

    result = @provider.artist_songs("Queen")
    assert_equal ["Song 1", "Song 2"], result[:songs]
    assert_equal 2, result[:current_page]
    assert_nil result[:next_page]
  end

  def test_artist_songs_with_max_pages
    stub_search_artist("Queen", 123)
    stub_artist_songs_page(123, 1, ["Song 1"], 2)
    stub_artist_songs_page(123, 2, ["Song 2"], 3)
    stub_artist_songs_page(123, 3, ["Song 3"], nil)

    result = @provider.artist_songs("Queen", max_pages: 2)
    assert_equal ["Song 1", "Song 2"], result[:songs]
    assert_equal 2, result[:current_page]
  end

  def test_artist_not_found
    stub_request(:get, /search/)
      .to_return(
        status: 200,
        body: { response: { hits: [] } }.to_json
      )

    result = @provider.artist_songs("Unknown Artist")
    assert_empty result[:songs]
    assert_equal 1, result[:current_page]
    assert_nil result[:next_page]
  end

  def test_api_timeout
    stub_request(:get, /search/).to_timeout
    result = @provider.artist_songs("Queen")
    assert_empty result[:songs]
    assert_equal 1, result[:current_page]
    assert_nil result[:next_page]
  end

  def test_api_500_error
    stub_request(:get, /search/).to_return(status: 500)
    result = @provider.artist_songs("Queen")
    assert_empty result[:songs]
    assert_equal 1, result[:current_page]
    assert_nil result[:next_page]
  end

  def test_invalid_json
    stub_request(:get, /search/).to_return(body: "invalid json", status: 200)
    result = @provider.artist_songs("Queen")
    assert_empty result[:songs]
    assert_equal 1, result[:current_page]
    assert_nil result[:next_page]
  end

  def test_empty_songs_in_page
    stub_search_artist("Queen", 123)
    stub_artist_songs_page(123, 1, [], nil)

    result = @provider.artist_songs("Queen")
    assert_empty result[:songs]
    assert_equal 1, result[:current_page]
    assert_nil result[:next_page]
  end

  def test_duplicate_song_titles
    stub_search_artist("Queen", 123)
    stub_artist_songs_page(123, 1, ["Song 1", "Song 1"], nil)

    result = @provider.artist_songs("Queen")
    assert_equal ["Song 1"], result[:songs]
  end
end
