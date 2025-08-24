#!/usr/bin/env ruby
# frozen_string_literal: true

require 'httparty'
require 'json'
require 'dotenv'

Dotenv.load

class GeniusClient
  BASE_URL = 'https://api.genius.com'

  def initialize
    @token = ENV['GENIUS_ACCESS_TOKEN']
    raise 'Missing GENIUS_ACCESS_TOKEN in .env' unless @token
  end

  # Search Genius API for a given artist name
  def search_artist_songs(artist_name, limit: 10)
    response = HTTParty.get(
      "#{BASE_URL}/search",
      headers: auth_header,
      query: { q: artist_name }
    )

    unless response.success?
      puts "❌ Request failed with status #{response.code}"
      return []
    end

    hits = response.parsed_response.dig('response', 'hits') || []

    # Filter results by artist name match
    songs = hits
      .select { |hit| hit.dig('result', 'primary_artist', 'name').downcase.include?(artist_name.downcase) }
      .map { |hit| hit.dig('result', 'full_title') }
      .uniq

    songs.take(limit)
  end

  private

  def auth_header
    { "Authorization" => "Bearer #{@token}" }
  end
end

# -------- Script Execution --------
if __FILE__ == $PROGRAM_NAME
  if ARGV.empty?
    puts "Usage: ruby genius_search.rb 'Artist Name'"
    exit
  end

  artist_name = ARGV.join(' ')
  client = GeniusClient.new
  songs = client.search_artist_songs(artist_name, limit: 20)

  if songs.empty?
    puts "No songs found for '#{artist_name}'."
  else
    puts "🎵 Top Songs for #{artist_name}:"
    songs.each_with_index do |song, index|
      puts "#{index + 1}. #{song}"
    end
  end
end
