# frozen_string_literal: true

RSpec.configure do |config|
  # Only clean database for ActiveRecord tests (type: :model, :controller)
  # Use direct SQL to avoid class name conflicts between PORO and ActiveRecord models
  config.before(:each, type: :model) do
    ActiveRecord::Base.connection.execute('DELETE FROM budget_payments')
    ActiveRecord::Base.connection.execute('DELETE FROM budget_line_items')
    ActiveRecord::Base.connection.execute('DELETE FROM budget_quotes')
  end

  config.before(:each, type: :controller) do
    ActiveRecord::Base.connection.execute('DELETE FROM budget_payments')
    ActiveRecord::Base.connection.execute('DELETE FROM budget_line_items')
    ActiveRecord::Base.connection.execute('DELETE FROM budget_quotes')
  end

  config.before(:each, type: :request) do
    ActiveRecord::Base.connection.execute('DELETE FROM budget_payments')
    ActiveRecord::Base.connection.execute('DELETE FROM budget_line_items')
    ActiveRecord::Base.connection.execute('DELETE FROM budget_quotes')
  end
end
