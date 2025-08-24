# frozen_string_literal: true

module Providers
  class BaseProvider
    # Contract: must return an array of song titles
    def artist_songs(_artist_name)
      raise NotImplementedError, "#{self.class} must implement #artist_songs"
    end
  end
end
