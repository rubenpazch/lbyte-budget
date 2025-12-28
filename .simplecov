# frozen_string_literal: true

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

  # Coverage thresholds
  minimum_coverage 99
  minimum_coverage_by_file 90

  # Configure formatters
  if ENV['CI']
    formatter SimpleCov::Formatter::SimpleFormatter
  else
    formatter SimpleCov::Formatter::HTMLFormatter
  end
end
