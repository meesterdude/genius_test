# frozen_string_literal: true

require "faraday"
require "faraday/retry"
require "json"
require "logger"
require_relative "base_provider"

module Providers
  class GeniusProvider < BaseProvider
    BASE_URL = "https://api.genius.com"

    def initialize(access_token:)
      @access_token = access_token
      @logger = Logger.new($stdout)
      @client = Faraday.new(BASE_URL) do |f|
        f.request :retry,
                  max: 3,
                  interval: 0.5,
                  backoff_factor: 2,
                  exceptions: [Faraday::TimeoutError, Faraday::ConnectionFailed]

        f.options.timeout = 5       # Read timeout
        f.options.open_timeout = 2  # Connection timeout
        f.adapter Faraday.default_adapter
      end
    end

    # Public interface
    def artist_songs(artist_name, start_page: 1, max_pages: nil)
      artist_id = search_artist_id(artist_name)
      return { current_page: start_page, songs: [], next_page: nil } unless artist_id

      fetch_all_songs(artist_id, artist_name, start_page, max_pages)
    rescue Faraday::TimeoutError
      @logger.warn "Timeout while fetching songs for '#{artist_name}'"
      { current_page: start_page, songs: [], next_page: nil }
    rescue Faraday::ClientError => e
      @logger.warn "Genius API client error: #{e.message}"
      { current_page: start_page, songs: [], next_page: nil }
    rescue JSON::ParserError
      @logger.warn "Invalid JSON from Genius API"
      { current_page: start_page, songs: [], next_page: nil }
    rescue StandardError => e
      @logger.warn "Unexpected error: #{e.message}"
      { current_page: start_page, songs: [], next_page: nil }
    end

    private

    def search_artist_id(artist_name)
      json = get("/search", { q: artist_name })
      hits = json.dig("response", "hits") || []

      hit = hits.find do |h|
        h.dig("result", "primary_artist", "name")&.casecmp?(artist_name)
      end

      hit&.dig("result", "primary_artist", "id")
    end

    def fetch_all_songs(artist_id, artist_name, start_page, max_pages)
      songs = []
      page = start_page

      loop do
        json = get("/artists/#{artist_id}/songs", per_page: 50, page: page)
        page_songs = json.dig("response", "songs") || []
        next_page = json.dig("response", "next_page")

        # Append current page's songs
        songs.concat(page_songs.map { |s| s["title"] })

        # Log progress
        if next_page
          @logger.info "Fetched page #{page} for #{artist_name}, next page: #{next_page}"
        else
          @logger.info "Fetched page #{page} for #{artist_name}, no more pages."
        end

        # Stop if there are no more pages
        break unless next_page

        # Stop if we've hit the max_pages limit (only if max_pages is set)
        break if max_pages && page >= max_pages

        page = next_page
      end

      {
        current_page: page,
        songs: songs.uniq,
        next_page: nil
      }
    end

    def get(path, params = {})
      response = @client.get(path, params, headers)
      unless response.status.between?(200, 299)
        raise Faraday::ClientError.new("Genius API error: #{response.status} #{response.reason_phrase}")
      end
      JSON.parse(response.body)
    end

    def headers
      { "Authorization" => "Bearer #{@access_token}" }
    end
  end
end
