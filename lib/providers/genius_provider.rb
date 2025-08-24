# frozen_string_literal: true

require "faraday"
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
        f.options.timeout = 5       # read timeout
        f.options.open_timeout = 2  # connection timeout
        f.adapter Faraday.default_adapter
      end
    end

    # Public interface
    # Returns an array of song titles, or empty array if anything goes wrong
    def artist_songs(artist_name)
      artist_id = search_artist_id(artist_name)
      return [] unless artist_id

      fetch_all_songs(artist_id)
    rescue Faraday::TimeoutError
      @logger.warn "Timeout while fetching songs for '#{artist_name}'"
      []
    rescue Faraday::ClientError => e
      @logger.warn "Genius API client error: #{e.message}"
      []
    rescue JSON::ParserError
      @logger.warn "Invalid JSON from Genius API"
      []
    rescue StandardError => e
      @logger.warn "Unexpected error: #{e.message}"
      []
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

    def fetch_all_songs(artist_id)
      songs = []
      page = 1

      loop do
        json = get("/artists/#{artist_id}/songs", per_page: 50, page: page)
        page_songs = json.dig("response", "songs") || []
        break if page_songs.empty?

        songs.concat(page_songs.map { |s| s["title"] })
        page += 1
      end

      songs.uniq
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
