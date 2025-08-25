# lib/providers/registry.rb
module Providers
  REGISTRY = {}

  Dir[File.join(__dir__, "*_provider.rb")].each do |file|
    require_relative File.basename(file)
    class_name = File.basename(file, ".rb").split("_").map(&:capitalize).join
    klass = Providers.const_get(class_name)
    name = File.basename(file, "_provider.rb").to_sym
    REGISTRY[name] = klass
  end

  def self.get(name, **options)
    klass = REGISTRY[name.to_sym] or raise ArgumentError, "Unknown provider: #{name}"
    klass.new(**options)
  end
end
