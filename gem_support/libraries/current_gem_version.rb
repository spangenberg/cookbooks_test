module Scalarium
  module GemSupport
    require 'rubygems/version'
    
    def gem_provider(name)
      resource = Chef::Resource::GemPackage.new(name, nil, node)
      provider_class = Chef::Platform.find_provider_for_node(node, resource)
      @gem_provider = provider_class.new(node, resource)
    end
    
    def current_gem_version(name)
      gem_provider(name).load_current_resource.version || "0"
    end
    
    def new_gem_version_available?(name)
      Chef::VERSION > "0.9" || ::Gem::Version.new(gem_provider(name).candidate_version) > ::Gem::Version.new(current_gem_version(name))
    end
    
    def gem_available?(name)
      Chef::VERSION > "0.9" || !gem_provider(name).candidate_version.nil?
    end

    def ensure_only_gem_version(name, ensured_version)
      versions = `gem list #{name}`
      versions = versions.scan(/(\d[a-zA-Z0-9\.]*)/)
      for version in versions
        version = version.first
        next if version == ensured_version
        gem_options = Proc.new do |version|
          action :uninstall
          version version
        end
        run_context.send(:gem_package, name, &gem_options(version))
      end

      gem_options = Proc.new do
        retries 2
        version ensured_version
      end
      run_context.send(:gem_package, name, &gem_options)
    end
  end
end

class Chef::Resource
  include Scalarium::GemSupport
end
class Chef::Recipe
  include Scalarium::GemSupport
end
