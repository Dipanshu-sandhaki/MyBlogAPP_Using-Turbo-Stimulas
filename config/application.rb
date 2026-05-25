require_relative "boot"

require "rails/all"

Bundler.require(*Rails.groups)

module TurboBlog
  class Application < Rails::Application
    config.load_defaults 7.1

    config.autoload_lib(ignore: %w(assets tasks))

    config.assets.paths << Rails.root.join("app/javascript")
    config.assets.precompile += Dir["app/javascript/controllers/*.js"].map { |f| "controllers/#{File.basename(f)}" }
  end
end