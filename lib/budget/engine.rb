# frozen_string_literal: true

module Budget
  # Rails Engine for Budget gem
  # Provides mountable engine functionality with isolated namespace
  class Engine < ::Rails::Engine
    isolate_namespace Budget

    # Ensure app directory is in autoload paths
    config.autoload_paths << "#{root}/app/models"
    config.autoload_paths << "#{root}/app/controllers"

    # Add views path for JBuilder templates
    config.paths['app/views'] ||= []
    config.paths['app/views'] << File.expand_path('../../app/views', __dir__)

    config.generators do |g|
      g.test_framework :rspec
      g.fixture_replacement :factory_bot
      g.factory_bot dir: 'spec/factories'
    end

    # Ensure models are loaded for associations in consuming apps
    initializer 'budget.eager_load_models', before: :set_autoload_paths do
      if Rails.env.development? || Rails.env.test?
        config.eager_load_paths << "#{root}/app/models"
      end
    end
  end
end
