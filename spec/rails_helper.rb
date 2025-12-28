# frozen_string_literal: true

require 'bundler/setup'

ENV['RAILS_ENV'] ||= 'test'

require 'simplecov'
SimpleCov.start do
  add_filter '/spec/'
  add_filter '/examples/'
  add_filter '/db/'
  add_filter '/config/'

  add_group 'ActiveRecord Models', 'app/models'
  add_group 'Controllers', 'app/controllers'
  add_group 'Views', 'app/views'
  add_group 'Engine', 'lib/budget/engine.rb'
  add_group 'Main', 'lib/budget.rb'

  minimum_coverage 100
  minimum_coverage_by_file 90
end

# Add lib to load path
$LOAD_PATH.unshift File.expand_path('../lib', __dir__)

# Load the dummy Rails app
require File.expand_path('dummy/config/environment', __dir__)

# Prevent database truncation if the environment is production
abort('The Rails environment is running in production mode!') if Rails.env.production?

require 'rspec/rails'
require 'timecop'

# Load support files
Dir[File.join(__dir__, 'support/**/*.rb')].each { |f| require f }

# Load the database schema
ActiveRecord::Schema.verbose = false
load File.expand_path('dummy/db/schema.rb', __dir__)

RSpec.configure do |config|
  # If you're not using ActiveRecord, or you'd prefer not to run each of your
  # examples within a transaction, remove the following line or assign false
  # instead of true.
  config.use_transactional_fixtures = true

  # RSpec Rails can automatically mix in different behaviours to your tests
  # based on their file location
  config.infer_spec_type_from_file_location!

  # Filter lines from Rails gems in backtraces.
  config.filter_rails_from_backtrace!

  config.expect_with :rspec do |c|
    c.syntax = :expect
  end
end
