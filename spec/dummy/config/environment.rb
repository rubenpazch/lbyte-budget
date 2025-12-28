# frozen_string_literal: true

require 'bundler/setup'
require 'rails'
require 'active_record/railtie'
require 'action_controller/railtie'
require 'action_view/railtie'

# Load all gems including the budget gem (which will load the engine)
Bundler.require(*Rails.groups)

# Explicitly require the budget engine to ensure it's loaded
require 'budget'
require 'budget/engine'

module Dummy
  class Application < Rails::Application
    config.load_defaults Rails::VERSION::STRING.to_f
    config.eager_load = true
    config.root = File.expand_path('..', __dir__)
    config.active_storage.service = :test if defined?(ActiveStorage)
  end
end

Rails.application.initialize! unless Rails.application.initialized?
