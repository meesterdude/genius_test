# lib/providers/registry.rb
module Providers
  REGISTRY = {}

  # Auto-load all files in this directory except base_provider.rb and registry.rb
  Dir[File.join(__dir__, "*.rb")].each do |file|
    require file
    next if file =~ /(base_provider|registry)\.rb$/

    # Infer the class from the filename
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
