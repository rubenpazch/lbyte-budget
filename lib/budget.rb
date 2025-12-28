# frozen_string_literal: true

require_relative 'budget/version'
require_relative 'budget/engine'

# Budget module provides quote/budget management functionality
# Rails Engine for managing quotes with line items and payments
module Budget
  class Error < StandardError; end
end
