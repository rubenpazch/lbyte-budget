# frozen_string_literal: true

module Budget
  # Rails Engine for Budget gem
  # Provides mountable engine functionality with isolated namespace
  class Engine < ::Rails::Engine
    isolate_namespace Budget

    # Ensure app directory is in autoload paths
    config.autoload_paths += %W[
      #{root}/app/models
      #{root}/app/controllers
    ]

    # Add views path for JBuilder templates
    config.paths['app/views'] ||= []
    config.paths['app/views'] << File.expand_path('../../app/views', __dir__)

    config.generators do |g|
      g.test_framework :rspec
      g.fixture_replacement :factory_bot
      g.factory_bot dir: 'spec/factories'
    end
  end
end
