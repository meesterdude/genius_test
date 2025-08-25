# test/registry_test.rb
require "test_helper"

class RegistryTest < Minitest::Test
  def test_registry_contains_genius_provider
    # Assumes you have GeniusProvider defined
    assert Providers::REGISTRY.key?(:genius)
    assert_equal Providers::GeniusProvider, Providers::REGISTRY[:genius]
  end

  def test_get_returns_instance
    provider = Providers.get(:genius, access_token: "FAKE_TOKEN")
    assert_instance_of Providers::GeniusProvider, provider
  end

  def test_get_unknown_provider_raises
    error = assert_raises(ArgumentError) do
      Providers.get(:unknown)
    end
    assert_match (/Unknown provider: unknown/), error.message
  end
end
