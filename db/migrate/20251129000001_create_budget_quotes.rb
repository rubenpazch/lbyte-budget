# frozen_string_literal: true

class CreateBudgetQuotes < ActiveRecord::Migration[7.0]
  def change
    create_table :budget_quotes do |t|
      t.string :customer_name, null: false
      t.string :customer_contact
      t.text :notes
      t.datetime :quote_date

      t.timestamps
    end

    add_index :budget_quotes, :customer_name
    add_index :budget_quotes, :created_at
  end
end
