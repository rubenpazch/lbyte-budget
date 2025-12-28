# frozen_string_literal: true

require 'rails/generators'
require 'rails/generators/migration'

module Budget
  module Generators
    # Rails generator for installing Budget migrations
    # Creates migrations for quotes, line items, and payments tables
    class InstallGenerator < Rails::Generators::Base
      include Rails::Generators::Migration

      source_root File.expand_path('../../../db/migrate', __dir__)

      desc 'Generates Budget migrations for quotes, line items, and payments'

      def self.next_migration_number(dirname)
        next_migration_number = current_migration_number(dirname) + 1
        ActiveRecord::Migration.next_migration_number(next_migration_number)
      end

      def copy_migrations
        migration_template '20251129000001_create_budget_quotes.rb', 'db/migrate/create_budget_quotes.rb'
        migration_template '20251129000002_create_budget_line_items.rb', 'db/migrate/create_budget_line_items.rb'
        migration_template '20251129000003_create_budget_payments.rb', 'db/migrate/create_budget_payments.rb'
      end

      def show_readme
        readme 'INSTALL' if behavior == :invoke
      end
    end
  end
end
